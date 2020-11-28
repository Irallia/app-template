# -----------------------------------------------------------------------------------------------------
# Copyright (c) 2006-2020, Knut Reinert & Freie Universität Berlin
# Copyright (c) 2016-2020, Knut Reinert & MPI für molekulare Genetik
# This file may be used, modified and/or redistributed under the terms of the 3-clause BSD-License
# shipped with this file and also available at: https://github.com/seqan/seqan3/blob/master/LICENSE.md
# -----------------------------------------------------------------------------------------------------

# Exposes the google-test targets `gtest` and `gtest_main`.
macro (require_test)
    enable_testing ()

    set (gtest_git_tag "release-1.10.0")

    if (NOT CMAKE_VERSION VERSION_LESS 3.14)
        message (STATUS "Fetch googletest:")

        include (FetchContent)
        FetchContent_Declare (
            gtest_fetch_content
            GIT_REPOSITORY "https://github.com/google/googletest.git"
            GIT_TAG "${gtest_git_tag}"
        )
        option (BUILD_GMOCK "" OFF)
        FetchContent_MakeAvailable(gtest_fetch_content)
    else ()
        message (STATUS "Use googletest as external project:")

        seqan3_require_test_old ("${gtest_git_tag}")
    endif ()

    add_custom_target (gtest_build DEPENDS gtest_main gtest)
endmacro ()
