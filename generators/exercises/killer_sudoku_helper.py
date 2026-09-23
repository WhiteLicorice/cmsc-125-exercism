FUNC_PROTO = """\
#include "vendor/unity.h"

#include <stddef.h>
#include <stdint.h>

#define MAX_ARRAY_SIZE 100
#define ARRAY_SIZE(x) (sizeof(x) / sizeof((x)[0]))

extern size_t combinations(uint32_t* dest, uint32_t sum, uint32_t size, uint32_t exclude);
"""


def _bitset(numbers):
    result = 0
    for number in numbers:
        result |= 1 << (number - 1)
    return result


def gen_func_body(prop, inp, expected):
    cage = inp["cage"]
    sm = cage["sum"]
    size = cage["size"]
    exclude = bin(_bitset(cage["exclude"]))

    combos = sorted(_bitset(combo) for combo in expected)
    expectation = "{ " + ", ".join(bin(c) for c in combos) + " }"

    str_list = []
    if len(expected) > 0:
        str_list.append(f"const uint32_t expected[] = {expectation};\n")
    str_list.append("uint32_t actual[MAX_ARRAY_SIZE];\n")
    str_list.append(
        f"const size_t size = combinations(actual, {sm}, {size}, {exclude});\n"
    )
    if len(expected) > 0:
        str_list.append("TEST_ASSERT_EQUAL_UINT(ARRAY_SIZE(expected), size);\n")
        str_list.append("TEST_ASSERT_EQUAL_UINT32_ARRAY(expected, actual, size);\n")
    else:
        str_list.append("TEST_ASSERT_EQUAL_UINT(0U, size);\n")
    return "".join(str_list)
