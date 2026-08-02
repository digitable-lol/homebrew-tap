class Digit < Formula
  desc "Portal-aware local AI agent by Digitable"
  homepage "https://github.com/digitable-lol/digit"
  url "https://github.com/digitable-lol/digit/archive/refs/tags/v0.19.2.tar.gz"
  sha256 "c8a1c9e1f22831f16b825d623d04f035512e1ef157b4f12600afa16b766c9b4f"
  license "MIT"

  depends_on "python@3.13"
  depends_on "uv"

  def install
    ENV["DIGIT_HOMEBREW_BUILD"] = "1"
    ENV["UV_CACHE_DIR"] = buildpath/".uv-cache"
    ENV["UV_PROJECT_ENVIRONMENT"] = libexec
    ENV["UV_PYTHON_DOWNLOADS"] = "never"

    system formula_opt_bin("uv")/"uv", "sync",
           "--frozen",
           "--no-dev",
           "--no-editable",
           "--python", formula_opt_bin("python@3.13")/"python3.13"

    site_packages = libexec/Language::Python.site_packages("python3.13")
    (site_packages/".install_method").write "homebrew\n"

    assets = pkgshare
    assets.install "skills", "optional-skills", "plugins", "locales", "optional-mcps"

    wrapper_env = {
      HERMES_BUNDLED_SKILLS:  assets/"skills",
      HERMES_OPTIONAL_SKILLS: assets/"optional-skills",
      HERMES_BUNDLED_PLUGINS: assets/"plugins",
      HERMES_BUNDLED_LOCALES: assets/"locales",
      HERMES_OPTIONAL_MCPS:   assets/"optional-mcps",
      HERMES_PYTHON:          libexec/"bin/python3",
    }

    %w[digit digit-agent digit-acp].each do |command|
      (bin/command).write_env_script libexec/"bin"/command, wrapper_env
    end
  end

  test do
    version_output = shell_output("#{bin}/digit --version")
    assert_match "Digit v#{version}", version_output
    assert_match "Install method: homebrew", version_output
    assert_match "usage: digit", shell_output("#{bin}/digit --help")
    assert_path_exists pkgshare/"skills/autonomous-ai-agents/digit/SKILL.md"
  end
end
