DEPS = [
    "//external:brpc",
    "//external:bthread",
    "//external:butil",
    "//external:gflags",
    "//external:glog",
    "@com_google_googletest//:gtest",
    "@com_google_googletest//:gtest_main",
]


cc_test(
    name = "perftest",
    srcs = ["atomic_executequeue.cpp"],
    copts = ["-std=c++14"],
    deps = DEPS,
)
