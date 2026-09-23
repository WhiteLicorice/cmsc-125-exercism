FUNC_PROTO = """\
#include "vendor/unity.h"

#define INVALID_NUMBER -1

extern int steps(long number);
"""


def gen_func_body(prop, inp, expected):
    number = inp["number"]
    if isinstance(expected, dict):
        expected = "INVALID_NUMBER"
    return f"TEST_ASSERT_EQUAL_INT({expected}, {prop}({number}));\n"
