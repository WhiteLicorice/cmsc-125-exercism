FUNC_PROTO = """\
#include "vendor/unity.h"

#define BUFFER_SIZE 20

typedef enum {
    INVALID_ROWS = -2,
    INVALID_COLUMNS = -1,
    SUCCESS = 0
} error_t;

extern error_t convert(char *buffer, const char *grid);
"""


def gen_func_body(prop, inp, expected):
    rows = inp["rows"]
    error = "SUCCESS"
    if isinstance(expected, dict) and "error" in expected:
        if expected["error"] == "Number of input lines is not a multiple of four":
            error = "INVALID_ROWS"
        else:
            error = "INVALID_COLUMNS"
        expected = ""

    str_list = []
    str_list.append("char buffer[BUFFER_SIZE];")
    str_list.append("const char grid[] =")
    for index in range(len(rows)):
        line = rows[index]
        if index + 1 < len(rows):
            str_list.append(f'    "{line}\\n"')
        else:
            str_list.append(f'    "{line}\\n";')

    str_list.append(f"TEST_ASSERT_EQUAL_INT({error}, {prop}(buffer, grid));")
    if error == "SUCCESS":
        str_list.append(f'TEST_ASSERT_EQUAL_STRING("{expected}", buffer);')
    return "\n".join(str_list) + "\n"
