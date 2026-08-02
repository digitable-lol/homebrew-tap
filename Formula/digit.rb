class Digit < Formula
  desc "Portal-aware local AI agent by Digitable"
  homepage "https://github.com/digitable-lol/digit"
  url "https://github.com/digitable-lol/digit/archive/refs/tags/v0.19.3.tar.gz"
  sha256 "4ac7bf502d53dd41d3a1893403b9c382069a7e628c1d7466cffd1fc5fba36d56"
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

    # Some Rust-backed Python wheels are incorrectly tagged as MH_DYLIB rather
    # than MH_BUNDLE. Homebrew then tries to give them a Cellar dylib ID, which
    # exceeds their Mach-O header padding. Convert those extension modules to
    # the bundle type expected by Python and remove the now-invalid dylib ID.
    if OS.mac?
      require "macho"

      libexec.glob("**/*.so").each do |shared_object|
        macho = MachO.open(shared_object)
        next unless macho.is_a?(MachO::MachOFile)
        next unless macho.dylib_id&.start_with?("@rpath/")

        macho.delete_command macho.command(:LC_ID_DYLIB).first
        raw_data = macho.serialize
        byte_order = (macho.endianness == :little) ? "V" : "N"
        raw_data[12, 4] = [MachO::Headers::MH_BUNDLE].pack(byte_order)
        shared_object.binwrite raw_data
        MachO.codesign! shared_object if Hardware::CPU.arm?
      end
    end

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
