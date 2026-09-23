#include "vendor/unity.h"

#include <stddef.h>
#include <stdint.h>

#define MAX_ARRAY_SIZE 100
#define ARRAY_SIZE(x) (sizeof(x) / sizeof((x)[0]))

extern size_t combinations(uint32_t* dest, uint32_t sum, uint32_t size, uint32_t exclude);

void setUp(void) {
}

void tearDown(void) {
}

void test_1(void) {
    const uint32_t expected[] = {0b1};
    uint32_t actual[MAX_ARRAY_SIZE];
    const size_t size = combinations(actual, 1, 1, 0b0);
    TEST_ASSERT_EQUAL_UINT(ARRAY_SIZE(expected), size);
    TEST_ASSERT_EQUAL_UINT32_ARRAY(expected, actual, size);
}

void test_2(void) {
    TEST_IGNORE();
    const uint32_t expected[] = {0b10};
    uint32_t actual[MAX_ARRAY_SIZE];
    const size_t size = combinations(actual, 2, 1, 0b0);
    TEST_ASSERT_EQUAL_UINT(ARRAY_SIZE(expected), size);
    TEST_ASSERT_EQUAL_UINT32_ARRAY(expected, actual, size);
}

void test_3(void) {
    TEST_IGNORE();
    const uint32_t expected[] = {0b100};
    uint32_t actual[MAX_ARRAY_SIZE];
    const size_t size = combinations(actual, 3, 1, 0b0);
    TEST_ASSERT_EQUAL_UINT(ARRAY_SIZE(expected), size);
    TEST_ASSERT_EQUAL_UINT32_ARRAY(expected, actual, size);
}

void test_4(void) {
    TEST_IGNORE();
    const uint32_t expected[] = {0b1000};
    uint32_t actual[MAX_ARRAY_SIZE];
    const size_t size = combinations(actual, 4, 1, 0b0);
    TEST_ASSERT_EQUAL_UINT(ARRAY_SIZE(expected), size);
    TEST_ASSERT_EQUAL_UINT32_ARRAY(expected, actual, size);
}

void test_5(void) {
    TEST_IGNORE();
    const uint32_t expected[] = {0b10000};
    uint32_t actual[MAX_ARRAY_SIZE];
    const size_t size = combinations(actual, 5, 1, 0b0);
    TEST_ASSERT_EQUAL_UINT(ARRAY_SIZE(expected), size);
    TEST_ASSERT_EQUAL_UINT32_ARRAY(expected, actual, size);
}

void test_6(void) {
    TEST_IGNORE();
    const uint32_t expected[] = {0b100000};
    uint32_t actual[MAX_ARRAY_SIZE];
    const size_t size = combinations(actual, 6, 1, 0b0);
    TEST_ASSERT_EQUAL_UINT(ARRAY_SIZE(expected), size);
    TEST_ASSERT_EQUAL_UINT32_ARRAY(expected, actual, size);
}

void test_7(void) {
    TEST_IGNORE();
    const uint32_t expected[] = {0b1000000};
    uint32_t actual[MAX_ARRAY_SIZE];
    const size_t size = combinations(actual, 7, 1, 0b0);
    TEST_ASSERT_EQUAL_UINT(ARRAY_SIZE(expected), size);
    TEST_ASSERT_EQUAL_UINT32_ARRAY(expected, actual, size);
}

void test_8(void) {
    TEST_IGNORE();
    const uint32_t expected[] = {0b10000000};
    uint32_t actual[MAX_ARRAY_SIZE];
    const size_t size = combinations(actual, 8, 1, 0b0);
    TEST_ASSERT_EQUAL_UINT(ARRAY_SIZE(expected), size);
    TEST_ASSERT_EQUAL_UINT32_ARRAY(expected, actual, size);
}

void test_9(void) {
    TEST_IGNORE();
    const uint32_t expected[] = {0b100000000};
    uint32_t actual[MAX_ARRAY_SIZE];
    const size_t size = combinations(actual, 9, 1, 0b0);
    TEST_ASSERT_EQUAL_UINT(ARRAY_SIZE(expected), size);
    TEST_ASSERT_EQUAL_UINT32_ARRAY(expected, actual, size);
}

void test_cage_with_sum_45_contains_all_digits_19(void) {
    TEST_IGNORE();
    const uint32_t expected[] = {0b111111111};
    uint32_t actual[MAX_ARRAY_SIZE];
    const size_t size = combinations(actual, 45, 9, 0b0);
    TEST_ASSERT_EQUAL_UINT(ARRAY_SIZE(expected), size);
    TEST_ASSERT_EQUAL_UINT32_ARRAY(expected, actual, size);
}

void test_cage_with_only_1_possible_combination(void) {
    TEST_IGNORE();
    const uint32_t expected[] = {0b1011};
    uint32_t actual[MAX_ARRAY_SIZE];
    const size_t size = combinations(actual, 7, 3, 0b0);
    TEST_ASSERT_EQUAL_UINT(ARRAY_SIZE(expected), size);
    TEST_ASSERT_EQUAL_UINT32_ARRAY(expected, actual, size);
}

void test_cage_with_several_combinations(void) {
    TEST_IGNORE();
    const uint32_t expected[] = {0b101000, 0b1000100, 0b10000010, 0b100000001};
    uint32_t actual[MAX_ARRAY_SIZE];
    const size_t size = combinations(actual, 10, 2, 0b0);
    TEST_ASSERT_EQUAL_UINT(ARRAY_SIZE(expected), size);
    TEST_ASSERT_EQUAL_UINT32_ARRAY(expected, actual, size);
}

void test_cage_with_several_combinations_that_is_restricted(void) {
    TEST_IGNORE();
    const uint32_t expected[] = {0b1000100, 0b10000010};
    uint32_t actual[MAX_ARRAY_SIZE];
    const size_t size = combinations(actual, 10, 2, 0b1001);
    TEST_ASSERT_EQUAL_UINT(ARRAY_SIZE(expected), size);
    TEST_ASSERT_EQUAL_UINT32_ARRAY(expected, actual, size);
}

int main(void) {
    UNITY_BEGIN();
    RUN_TEST(test_1);
    RUN_TEST(test_2);
    RUN_TEST(test_3);
    RUN_TEST(test_4);
    RUN_TEST(test_5);
    RUN_TEST(test_6);
    RUN_TEST(test_7);
    RUN_TEST(test_8);
    RUN_TEST(test_9);
    RUN_TEST(test_cage_with_sum_45_contains_all_digits_19);
    RUN_TEST(test_cage_with_only_1_possible_combination);
    RUN_TEST(test_cage_with_several_combinations);
    RUN_TEST(test_cage_with_several_combinations_that_is_restricted);
    return UNITY_END();
}
