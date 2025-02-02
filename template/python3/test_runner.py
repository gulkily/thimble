#!/usr/bin/env python3

import os
import sys
import unittest

class CompactTestResult(unittest.TextTestResult):
    def printErrors(self):
        # Only print errors and failures
        if self.errors or self.failures:
            super().printErrors()
    
    def getDescription(self, test):
        # Return just the test name without the module and class
        return test._testMethodName

def run_all_tests():
    # Discover and run all tests
    loader = unittest.TestLoader()
    start_dir = os.path.join(os.path.dirname(__file__))  # Look in the current template directory
    suite = loader.discover(start_dir, pattern='test_*.py')
    
    # Run the test suite with compact output
    runner = unittest.TextTestRunner(resultclass=CompactTestResult, verbosity=1)
    result = runner.run(suite)
    
    return result.wasSuccessful()

if __name__ == '__main__':
    success = run_all_tests()
    sys.exit(0 if success else 1)
