# todotxt setup
() {
    local TODO_FOLDER="$HOME/Documents/todo"
    alias todo="nvim '$TODO_FOLDER/todo.txt'"
    alias todo-plan="cd '$TODO_FOLDER' && claude"
}

# Date utilities
alias week="date +%U"
alias today='date +%F'
