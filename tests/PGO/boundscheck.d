// Test instrumentation of autogenerated boundschecking calls

// Boundschecks are inserted for (a) array indexing and (b) array slicing.

// Boundschecks should not be instrumented.
// The fail branch of a boundscheck goes to a basicblock that terminates in
// 'unreachable'. This means that LLVM will already assign minimum probability
// to the fail branch and maximum probability to the pass branch. See the
// documentation of UR_TAKEN_WEIGHT and UR_NONTAKEN_WEIGHT in file
// "llvm/Analysis/BranchProbabilityInfo.cpp".
// Adding instrumentation to boundschecks would only add runtime overhead at
// zero benefit.

// The tests here check for the absence of the instrumentation of boundschecks.

// RUN: %ldc -c -output-ll -fprofile-instr-generate -of=%t.ll %s && FileCheck %s --check-prefix=PROFGEN < %t.ll

// PROFGEN: @[[MAIN:__(llvm_profile_counters|profc)__Dmain]] ={{.*}} global [1 x i64] zeroinitializer

// PROFGEN-LABEL: @_Dmain(
// PROFGEN: store {{.*}} @[[MAIN]]
@safe:
void main() {
  int[] array = [1,2,3];

  // PROFGEN-NOT: store {{.*}} @[[MAIN]]
  auto one = array[2];    // (a) array indexing
  auto two = array[1..2]; // (b) array slicing
}
