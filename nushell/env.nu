$env.PATH = ($env.PATH | split row (char esep) | prepend [
    ($env.HOME | path join ".local" "bin")
    ($env.HOME | path join "bin")
    ($env.HOME | path join "go" "bin")
])

$env.EDITOR = "nvim"
$env.CMAKE_BUILD_PARALLEL_LEVEL = "16"
$env.CMAKE_EXPORT_COMPILE_COMMANDS = "1"
