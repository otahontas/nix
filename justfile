[private]
default:
    @echo "No default recipe. Run 'just --list' to see available recipes."
    @exit 1

apply-home:
    just home/apply

apply-system:
    just system/apply

update-home:
    just home/update

update-system:
    just system/update

format:
    treefmt -v
