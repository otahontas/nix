function todo
    set -l p (todo_path); or return 1
    nvim "$p"
end

function daily
    set -l p (daily_path); or return 1
    nvim "$p"
end
