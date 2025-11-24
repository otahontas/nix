# Olympia - A warm, light colorscheme for Nushell
# https://github.com/otahontas/olympia
#
# All colors from Helsinki värikaava (Olympiakylä):
# https://www.hel.fi/static/rakvv/varikaava/htm/21002.htm

# =============================================================================
# Theme Definition (static colors only - closures not allowed in const)
# =============================================================================

export const olympia_theme = {
    # Separators and borders
    separator: "#9f9c91"

    # Table header
    leading_trailing_space_bg: { attr: "n" }
    header: { fg: "#a07647" attr: "b" }
    empty: "#9f9c91"

    # Data types (static colors)
    bool: "#a07647"
    int: "#a07647"
    float: "#a07647"
    filesize: "#a07647"
    duration: "#a07647"
    date: "#7f796c"
    range: "#a07647"
    string: "#545554"
    nothing: "#9f9c91"
    binary: "#835f43"
    cell_path: "#7f796c"
    row_index: { fg: "#9f9c91" attr: "b" }
    record: "#545554"
    list: "#545554"
    block: "#7f796c"
    hints: "#9f9c91"
    search_result: { fg: "#545554" bg: "#e8ce93" }

    # Shapes (syntax highlighting in the REPL)
    shape_and: { fg: "#765c49" attr: "b" }
    shape_binary: "#835f43"
    shape_block: { fg: "#7f796c" attr: "b" }
    shape_bool: "#a07647"
    shape_closure: { fg: "#747362" attr: "b" }
    shape_custom: "#a07647"
    shape_datetime: { fg: "#7f796c" attr: "b" }
    shape_directory: "#8c9187"
    shape_external: "#7f796c"
    shape_externalarg: "#545554"
    shape_external_resolved: { fg: "#747362" attr: "b" }
    shape_filepath: "#8c9187"
    shape_flag: { fg: "#765c49" attr: "b" }
    shape_float: { fg: "#a07647" attr: "b" }
    shape_garbage: { fg: "#e9e2d1" bg: "#754742" attr: "b" }
    shape_glob_interpolation: { fg: "#7f796c" attr: "b" }
    shape_globpattern: { fg: "#7f796c" attr: "b" }
    shape_int: { fg: "#a07647" attr: "b" }
    shape_internalcall: { fg: "#a07647" attr: "b" }
    shape_keyword: { fg: "#765c49" attr: "b" }
    shape_list: { fg: "#7f796c" attr: "b" }
    shape_literal: "#a07647"
    shape_match_pattern: "#747362"
    shape_matching_brackets: { attr: "u" }
    shape_nothing: "#9f9c91"
    shape_operator: "#6b5d53"
    shape_or: { fg: "#765c49" attr: "b" }
    shape_pipe: { fg: "#765c49" attr: "b" }
    shape_range: { fg: "#6b5d53" attr: "b" }
    shape_raw_string: { fg: "#747362" attr: "b" }
    shape_record: { fg: "#7f796c" attr: "b" }
    shape_redirection: { fg: "#765c49" attr: "b" }
    shape_signature: { fg: "#747362" attr: "b" }
    shape_string: "#747362"
    shape_string_interpolation: { fg: "#7f796c" attr: "b" }
    shape_table: { fg: "#8c9187" attr: "b" }
    shape_variable: "#765c49"
    shape_vardecl: { fg: "#765c49" attr: "u" }

    # Background highlighting
    background: "#dbd6cb"
    foreground: "#545554"
    cursor: "#a07647"
}

# =============================================================================
# Menu Styling
# =============================================================================

export const olympia_menus = [
    {
        name: completion_menu
        only_buffer_difference: false
        marker: "| "
        type: {
            layout: columnar
            columns: 4
            col_width: 20
            col_padding: 2
        }
        style: {
            text: "#545554"
            selected_text: { fg: "#545554" bg: "#e8ce93" attr: "b" }
            description_text: "#9f9c91"
            match_text: { fg: "#a07647" attr: "b" }
            selected_match_text: { fg: "#a07647" bg: "#e8ce93" attr: "b" }
        }
    }
    {
        name: ide_completion_menu
        only_buffer_difference: false
        marker: "| "
        type: {
            layout: ide
            min_completion_width: 0
            max_completion_width: 50
            max_completion_height: 10
            padding: 0
            border: true
            cursor_offset: 0
            description_mode: "prefer_right"
            min_description_width: 0
            max_description_width: 50
            max_description_height: 10
            description_offset: 1
            correct_cursor_pos: false
        }
        style: {
            text: "#545554"
            selected_text: { fg: "#545554" bg: "#e8ce93" attr: "b" }
            description_text: "#9f9c91"
            match_text: { fg: "#a07647" attr: "b" }
            selected_match_text: { fg: "#a07647" bg: "#e8ce93" attr: "b" }
        }
    }
    {
        name: history_menu
        only_buffer_difference: true
        marker: "? "
        type: {
            layout: list
            page_size: 10
        }
        style: {
            text: "#545554"
            selected_text: { fg: "#545554" bg: "#e8ce93" attr: "b" }
            description_text: "#9f9c91"
        }
    }
    {
        name: help_menu
        only_buffer_difference: true
        marker: "? "
        type: {
            layout: description
            columns: 4
            col_width: 20
            col_padding: 2
            selection_rows: 4
            description_rows: 10
        }
        style: {
            text: "#545554"
            selected_text: { fg: "#545554" bg: "#e8ce93" attr: "b" }
            description_text: "#9f9c91"
        }
    }
]
