#include <atomic>
#include <gtest/gtest.h>
#include <gflags/gflags.h>
#include <glog/logging.h>
#include <bthread/bthread.h>
#include <bthread/execution_queue.h>
#include <brpc/channel.h>
#include <brpc/controller.h>
#include <brpc/server.h>


class ExecutionQueueTest : public testing::Test {

};

struct AtomicArg {
    AtomicArg() : cnt(0), timeElapsedMs(0), stop(false) { }
    std::atomic<int64_t> cnt;
    std::atomic<int64_t> timeElapsedMs;
    std::atomic<bool> stop;
};

void* AddThreadFunc(void *arg) {
    AtomicArg *atomicArg = reinterpret_cast<AtomicArg *>(arg);
    butil::Timer timer;
    timer.start();
    while (!atomicArg->stop.load()) {
        atomicArg->cnt.fetch_add(1);
    }
    timer.stop();
    atomicArg->timeElapsedMs.fetch_add(timer.m_elapsed());
}


TEST_F(ExecutionQueueTest, atomic_performance_cmp) {
    LOG(INFO) << "\n\n\n" << "atomic performance cmp: \n\n";
    int testTimeIntervelus = 5000 * 1000;
    std::vector<int> threadsNums = {1, 2, 3, 4, 5, 6, 7, 8,
                                  9, 10, 11, 12, 13, 14, 15, 16};
    for (size_t i = 0; i < threadsNums.size(); ++i) {
        AtomicArg atomicArg;
        std::vector<pthread_t> threads(threadsNums[i]);
        for (int j=0; j<threadsNums[i]; ++j) {
            pthread_create(&threads[i],
                           NULL,
                           &AddThreadFunc,
                           &atomicArg);
        }

        bthread_usleep(testTimeIntervelus);

        atomicArg.stop.store(true);

        for (size_t k = 0; k < threads.size(); ++k) {
            pthread_join(threads[i], NULL);
        }

        double totalCnt = atomicArg.cnt.load();
        LOG(INFO) << "Threads number: " << threadsNums[i] << " "
                  << totalCnt/10000 << "w " << totalCnt/(atomicArg.timeElapsedMs/1000)/10000 << " w/s";
    }
}
