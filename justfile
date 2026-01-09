[private]
default:
    @echo "No default recipe. Run 'just --list' to see available recipes."
    @exit 1

apply-home:
    just home/apply

apply-system:
    just system/apply

update:
    just home/update
    just system/update

format:
    treefmt -v
