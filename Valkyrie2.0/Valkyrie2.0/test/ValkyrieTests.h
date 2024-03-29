#pragma once
#include "../libs/BaseTypes.h"

class ValkyrieTests {
private:
	int total_;
	int passed_;
	std::vector<std::string> failedTests;
	std::vector<std::string> passedTests;
	void runParserTests();
	void runStagingTests();
	void runCPUDeviceTests();
	void runGPUDeviceTests();
	void runMeasurementTests();
	void runStateVectorTests();
public:	
	ValkyrieTests();
	void runTests();
	void handleTestResult(bool res, std::string testDescription);
	double getPercentagePassed();
	int noPassed() { return passed_; }
	std::vector<std::string> testsFailed();
};