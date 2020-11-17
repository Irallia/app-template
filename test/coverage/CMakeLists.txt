cmake_minimum_required (VERSION 3.8)
project (fastq_to_fasta_test_coverage CXX)

if (CMAKE_BUILD_TYPE AND NOT ("${CMAKE_BUILD_TYPE}" STREQUAL "Debug"))
    message(WARNING "Coverage test must be build in debug mode [build type = ${CMAKE_BUILD_TYPE}]")
endif ()

find_program (LCOV_COMMAND  NAMES lcov lcov.bat lcov.exe lcov.perl)
find_program (GENHTML_COMMAND NAMES genhtml genhtml.perl genhtml.bat)

if (NOT LCOV_COMMAND)
    message(FATAL_ERROR "lcov not found! Aborting...")
endif ()

# Files which should not be included in the coverage report
set (TEST_COVERAGE_EXCLUDE_FILES
    "'/usr/*'"
    "'${SEQAN3_CLONE_DIR}/lib/*'"
    "'${SEQAN3_CLONE_DIR}/test/api/*'"
    "'${SEQAN3_CLONE_DIR}/test/cli/*'"
    "'${PROJECT_BINARY_DIR}/vendor/*'"
)
# Holds all target's defined by fastq_to_fasta_test
set_property (GLOBAL PROPERTY GLOBAL_TEST_COVERAGE_ALL_TESTS "")

add_custom_command (
    OUTPUT ${PROJECT_BINARY_DIR}/fastq_to_fasta_coverage
    # Cleanup lcov (resetting code coverage counters to zero)
    COMMAND ${LCOV_COMMAND} --directory ${PROJECT_BINARY_DIR} --zerocounters
    # Create baseline to make sure untouched files show up in the report
    COMMAND ${LCOV_COMMAND} --directory ${PROJECT_BINARY_DIR} --capture --initial --output-file ${PROJECT_BINARY_DIR}/fastq_to_fasta_coverage.baseline

    # Run tests
    COMMAND ${CMAKE_CTEST_COMMAND}

    # Capturing lcov counters and generating report
    COMMAND ${LCOV_COMMAND} --directory ${PROJECT_BINARY_DIR} --capture --output-file ${PROJECT_BINARY_DIR}/fastq_to_fasta_coverage.captured
    # merge baseline counters and captured counters
    COMMAND ${LCOV_COMMAND} -a ${PROJECT_BINARY_DIR}/fastq_to_fasta_coverage.baseline -a ${PROJECT_BINARY_DIR}/fastq_to_fasta_coverage.captured --output-file ${PROJECT_BINARY_DIR}/fastq_to_fasta_coverage.total
    COMMAND ${LCOV_COMMAND} --remove ${PROJECT_BINARY_DIR}/fastq_to_fasta_coverage.total ${TEST_COVERAGE_EXCLUDE_FILES} --output-file ${PROJECT_BINARY_DIR}/fastq_to_fasta_coverage

    BYPRODUCTS fastq_to_fasta_coverage.baseline fastq_to_fasta_coverage.captured fastq_to_fasta_coverage.total

    WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
    COMMENT "Processing code coverage counters."
)
set_directory_properties(PROPERTIES ADDITIONAL_MAKE_CLEAN_FILES "fastq_to_fasta_coverage.baseline;fastq_to_fasta_coverage.captured;fastq_to_fasta_coverage.total")

add_custom_target (
    coverage ALL
    DEPENDS
    ${PROJECT_BINARY_DIR}/fastq_to_fasta_coverage
)

add_custom_target (
    coverage_html
    COMMAND ${GENHTML_COMMAND} --highlight --legend --output-directory html ${PROJECT_BINARY_DIR}/fastq_to_fasta_coverage
    WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
    DEPENDS coverage
    COMMENT "Generate coverage report."
)

add_custom_command(
    TARGET coverage_html POST_BUILD
    COMMAND ;
    COMMENT "Open ${PROJECT_BINARY_DIR}/html/index.html in your browser to view the coverage report."
)

macro (fastq_to_fasta_test api_test_cpp cli_test_cpp)
    file (RELATIVE_PATH api_test "${CMAKE_SOURCE_DIR}/../api" "${CMAKE_CURRENT_LIST_DIR}/${api_test_cpp}")
    file (RELATIVE_PATH cli_test "${CMAKE_SOURCE_DIR}/../cli" "${CMAKE_CURRENT_LIST_DIR}/${cli_test_cpp}")
    fastq_to_fasta_test_component (target "${api_test}" TARGET_NAME)
    fastq_to_fasta_test_component (target "${cli_test}" TARGET_NAME)
    fastq_to_fasta_test_component (test_name "${api_test}" TEST_NAME)
    fastq_to_fasta_test_component (test_name "${cli_test}" TEST_NAME)

    add_executable (${target} ${api_test_cpp})
    add_executable (${target} ${cli_test_cpp})
    target_link_libraries (${target} fastq_to_fasta::test::coverage)
    add_test (NAME "${test_name}" COMMAND ${target})

    # any change of a target will invalidate the coverage result;
    # NOTE that this is a GLOBAL variable, because a normal
    # `set(GLOBAL_TEST_COVERAGE_ALL_TESTS)` would not propagate the result when
    # CMakeLists.txt goes out of scope due to a `add_subdirectory`
    set_property(GLOBAL APPEND PROPERTY GLOBAL_TEST_COVERAGE_ALL_TESTS ${target})

    unset (api_test)
    unset (cli_test)
    unset (target)
    unset (test_name)
endmacro ()

# fastq_to_fasta_require_ccache ()
# fastq_to_fasta_require_test ()

# add all api & cli tests
add_subdirectories_of ("${CMAKE_CURRENT_SOURCE_DIR}/../api")
add_subdirectories_of ("${CMAKE_CURRENT_SOURCE_DIR}/../cli")

# add collected test cases as dependency
get_property(TEST_COVERAGE_ALL_TESTS GLOBAL PROPERTY GLOBAL_TEST_COVERAGE_ALL_TESTS)
add_custom_command (
    OUTPUT ${PROJECT_BINARY_DIR}/fastq_to_fasta_coverage
    DEPENDS ${TEST_COVERAGE_ALL_TESTS}
    APPEND
)
