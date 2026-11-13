import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[1]
APPS = {
    "brave-browser": "Brave Browser",
    "tailscale-app": "Tailscale",
    "wezterm": "WezTerm",
    "maccy": "Maccy",
    "visual-studio-code": "Visual Studio Code",
    "docker-desktop": "Docker",
    "keepingyouawake": "KeepingYouAwake",
    "google-chrome": "Google Chrome",
}

# Each external tool is replaced so a bootstrap can run against an empty home.
MOCK_TOOL = r'''
import os
from pathlib import Path
import shlex
import sys

root = Path(os.environ["SETUP_TEST_ROOT"])
home = Path(os.environ["HOME"])
name = Path(sys.argv[0]).name
args = sys.argv[1:]

def executable(path, body="#!/bin/sh\nexit 0\n"):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(body)
    path.chmod(0o755)

def record(value):
    with (root / "installs").open("a") as log:
        log.write(value + "\n")

if name == "uname":
    print("Darwin" if args == ["-s"] else "arm64")
elif name == "id":
    print("501")
elif name == "xcode-select":
    sys.exit(1 if os.environ.get("SETUP_TEST_NO_CLT") else 0)
elif name == "brew":
    if args == ["shellenv"]:
        print("export PATH=" + shlex.quote(str(root / "opt/homebrew/bin")) + ':"$PATH"')
    elif args[:2] == ["list", "--versions"]:
        sys.exit(0 if (root / "formulae" / args[2]).exists() else 1)
    elif args[0] == "install":
        if args[1] == "--cask":
            cask = args[2]
            if cask == os.environ.get("SETUP_TEST_FAIL_CASK"):
                sys.exit(42)
            app = root / "Applications" / (APPS[cask] + ".app")
            app.mkdir(parents=True)
            if cask == "visual-studio-code":
                executable(app / "Contents/Resources/app/bin/code")
            record("cask " + cask)
        else:
            pkg = args[1]
            marker = root / "formulae" / pkg
            marker.parent.mkdir(exist_ok=True)
            marker.touch()
            cmd = {"ripgrep": "rg"}.get(pkg, pkg)
            executable(root / "bin" / cmd)
            if pkg == "node":
                shutil.copy2(root / "tool", root / "bin/npm")
            record("formula " + pkg)
elif name == "npm":
    executable(root / "bin" / args[-1])
    record("npm " + args[-1])
elif name == "curl":
    url = next(arg for arg in args if arg.startswith("https://"))
    if "Homebrew/install" in url:
        script = '#!/bin/sh\nmkdir -p "$SETUP_TEST_ROOT/opt/homebrew/bin"\ncp "$SETUP_TEST_ROOT/tool" "$SETUP_TEST_ROOT/opt/homebrew/bin/brew"\nprintf "homebrew\\n" >> "$SETUP_TEST_ROOT/installs"\n'
    else:
        cmd = next(cmd for key, cmd in (("herdr.dev", "herdr"), ("treehouse/", "treehouse"), ("chatgpt.com/", "codex"), ("claude.ai/", "claude")) if key in url)
        target = "$HOME/.local/bin"
        script = f'#!/bin/sh\nmkdir -p "{target}"\nprintf "#!/bin/sh\\nexit 0\\n" > "{target}/{cmd}"\nchmod +x "{target}/{cmd}"\nprintf "native {cmd}\\n" >> "$SETUP_TEST_ROOT/installs"\n'
    if "-o" in args:
        Path(args[args.index("-o") + 1]).write_text(script)
    else:
        print(script)
else:
    raise SystemExit("Unexpected tool: " + name)
'''


class BootstrapTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="dev-setup-test-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.repo = self.root / "repo"
        self.home = self.root / "home"
        self.bins = self.root / "bin"
        self.home.mkdir()
        self.bins.mkdir()
        shutil.copytree(REPO / "scripts", self.repo / "scripts")
        shutil.copytree(REPO / "dotfiles/wezterm", self.repo / "dotfiles/wezterm")
        shutil.copytree(
            REPO / "dotfiles/home", self.repo / "dotfiles/home",
            ignore=shutil.ignore_patterns(".codex"),
        )
        # Map system locations into the fixture; every mutation stays in it.
        for file in [*(self.repo / "scripts").rglob("*.sh"), self.repo / "dotfiles/home/.zprofile"]:
            text = file.read_text().replace('"/Applications/', f'"{self.root}/Applications/')
            text = text.replace("/opt/homebrew/bin/brew", str(self.root / "opt/homebrew/bin/brew"))
            text = text.replace("/usr/local/bin/brew", str(self.root / "usr/local/bin/brew"))
            file.write_text(text)
        tool = self.root / "tool"
        tool.write_text(f"#!{sys.executable}\nimport shutil\nAPPS = {APPS!r}\n" + MOCK_TOOL)
        tool.chmod(0o755)
        for cmd in ("uname", "id", "xcode-select", "curl"):
            shutil.copy2(tool, self.bins / cmd)
        self.env = dict(os.environ, HOME=str(self.home), PATH=f"{self.bins}:/usr/bin:/bin", SHELL="/bin/zsh", SETUP_TEST_ROOT=str(self.root))

    def run_script(self, name="bootstrap", success=True, **extra):
        result = subprocess.run(
            ["/bin/bash", str(self.repo / f"scripts/{name}.sh")],
            env=dict(self.env, **extra), text=True, capture_output=True,
        )
        if success:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    def installs(self):
        return (self.root / "installs").read_text().splitlines()

    def test_fresh_mac_and_repeat_run(self):
        self.run_script()
        installed = self.installs()
        self.assertIn("homebrew", installed)
        self.assertIn("formula git", installed)
        self.assertIn("formula gh", installed)
        for cask in APPS:
            self.assertIn("cask " + cask, installed)
        for cmd in ("herdr", "treehouse", "codex", "claude"):
            self.assertIn("native " + cmd, installed)
        self.assertFalse((self.home / ".local/bin/grok").exists())
        self.assertNotIn("native grok", installed)
        self.assertEqual((self.home / ".local/bin/code").resolve(), self.root / "Applications/Visual Studio Code.app/Contents/Resources/app/bin/code")
        self.run_script()
        self.assertEqual(self.installs(), installed)
        self.assertFalse(list(self.home.glob(".dotfiles-backup*")))

    def test_preserve_existing_apps_and_backup_configs(self):
        for app in APPS.values():
            path = self.home / "Applications" / (app + ".app")
            path.mkdir(parents=True)
            if app == "Visual Studio Code":
                cli = path / "Contents/Resources/app/bin/code"
                cli.parent.mkdir(parents=True)
                cli.write_text("#!/bin/sh\nexit 0\n")
                cli.chmod(0o755)
        (self.home / ".wezterm.lua").write_text("existing wezterm config")
        (self.home / ".zshrc").write_text("existing shell config")
        (self.home / ".codex").mkdir()
        (self.home / ".codex/config.toml").write_text("# local test config\n")
        self.run_script()
        self.assertFalse(any(item.startswith("cask ") for item in self.installs()))
        self.assertEqual(next(self.home.glob(".dotfiles-backup-wezterm.*/.wezterm.lua")).read_text(), "existing wezterm config")
        self.assertEqual(next(self.home.glob(".dotfiles-backup/*/.zshrc")).read_text(), "existing shell config")
        self.assertTrue((self.home / ".codex/config.toml").is_symlink())
        self.assertEqual((self.repo / "dotfiles/home/.codex/config.toml").read_text(), "# local test config\n")
        self.run_script()
        self.assertEqual(len(list(self.home.glob(".dotfiles-backup-wezterm.*"))), 1)

    def test_resume_after_failed_package_install(self):
        self.run_script(success=False, SETUP_TEST_FAIL_CASK="maccy")
        self.assertFalse((self.home / ".zshrc").exists())
        self.run_script()
        self.assertEqual(self.installs().count("cask brave-browser"), 1)

    def test_missing_command_line_tools_explains_next_step(self):
        result = self.run_script(success=False, SETUP_TEST_NO_CLT="1")
        self.assertIn("xcode-select --install", result.stderr)
        self.assertFalse((self.root / "installs").exists())

    def test_check_detects_broken_installation_without_repairing_it(self):
        self.run_script()
        (self.home / ".local/bin/codex").unlink()
        (self.home / ".codex/AGENTS.md").unlink()
        (self.home / ".wezterm.lua").write_text("different config")
        result = self.run_script("check", success=False)
        self.assertIn("MISSING: command codex", result.stdout)
        self.assertIn("MISSING: .codex/AGENTS.md", result.stdout)
        self.assertIn("MISSING: WezTerm config matches repo", result.stdout)
        self.assertEqual((self.home / ".wezterm.lua").read_text(), "different config")

    @unittest.skipUnless(Path("/bin/zsh").is_file(), "requires a real zsh")
    def test_new_login_shell_finds_tools_and_aliases(self):
        self.run_script()
        result = subprocess.run(
            ["/bin/zsh", "-lic", 'for cmd in brew git gh node npm herdr treehouse codex claude code; do command -v "$cmd" >/dev/null || exit 1; done; alias cx cc'],
            env=dict(self.env, ZDOTDIR=str(self.home), SSH_AUTH_SOCK="/dev/null"),
            text=True, capture_output=True,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("dangerously-bypass-approvals-and-sandbox", result.stdout)
        self.assertIn("dangerously-skip-permissions", result.stdout)

    def test_bash_preserves_inherited_wsl_path_and_completes_case_insensitively(self):
        (self.home / ".local/bin").mkdir(parents=True)
        (self.home / ".local/node/bin").mkdir(parents=True)
        (self.home / "MiXeD").mkdir()
        result = subprocess.run(
            ["/bin/bash", "--noprofile", "--rcfile", str(self.repo / "dotfiles/home/.bashrc"), "-ic",
             'printf "%s\\n" "$PATH"; COMP_WORDS=(cd mix); COMP_CWORD=1; _cd_substring_complete; printf "%s\\n" "${COMPREPLY[@]}"; shopt -q nocasematch && exit 1; shopt -s nocasematch; _cd_substring_complete; shopt -q nocasematch'],
            cwd=self.home,
            env=dict(self.env, WSL_DISTRO_NAME="Ubuntu", TERM="dumb"),
            text=True, capture_output=True,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn(str(self.bins), result.stdout.splitlines()[0].split(":"))
        self.assertIn(str(self.home / ".local/node/bin"), result.stdout.splitlines()[0].split(":"))
        self.assertIn("MiXeD", result.stdout.splitlines()[1:])
        self.assertNotIn("/home/sergiodallavalle", result.stdout)
        self.assertNotIn("bad substitution", result.stderr)


if __name__ == "__main__":
    unittest.main()
