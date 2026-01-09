# Fish function to set/unset AWS_PROFILE
function awsp -d "Set or unset AWS_PROFILE"
    if test (count $argv) -eq 0
        set -e AWS_PROFILE
        echo "AWS_PROFILE unset"
    else
        set -l profile $argv[1]
        # Validate profile exists
        if not aws configure list-profiles 2>/dev/null | string match -q -- $profile
            echo "Profile '$profile' not found in AWS config" >&2
            return 1
        end
        set -gx AWS_PROFILE $profile
        echo "AWS_PROFILE set to '$profile'"
    end
end

# Autocompletion for awsp - complete with available AWS profiles
complete -c awsp -f -a "(aws configure list-profiles 2>/dev/null)"
