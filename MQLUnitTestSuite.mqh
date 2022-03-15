//+------------------------------------------------------------------+
//|                                                          MQLUnit |
//|                                   Copyright 2021, Niklas Schlimm |
//|                             https://github.com/nschlimm/MQL5Unit |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Niklas Schlimm"
#property link      "https://github.com/nschlimm/MQL5Unit"
#property version   "1.00"

#include <Object.mqh>
#include <Arrays\List.mqh>
#include "MQLUnitTestAsserts.mqh"

enum ENUM_TEST_EXEC_STATE
  {
   PENDING,
   EXECUTED
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
typedef CUnitTestAsserts*(*UnitTest)();
typedef void(*Setup)();
typedef void(*TearDown)();

//+------------------------------------------------------------------+
//| Suite of unit tests
//+------------------------------------------------------------------+
class CUnitTestSuite: public CObject
  {
private:
   CList             m_unitTestsAssertList;

   UnitTest          m_unitTestFunc_OnInit[];
   UnitTest          m_unitTestFunc_OnNewCandle[];
   int               m_ExecuteOnCandleCount[][2]; // holds canlde count on which to execute test and execution status
   Setup             m_setupFunc_OnNewCandle[];
   int               m_SetupExecuteOnCandleCount[][2]; // holds canlde count on which to setup function and execution status
   TearDown          m_tearDownFunc_OnNewCandle[];
   int               m_TearDownExecuteOnCandleCount[][2]; // holds canlde count on which to teardown function and execution status
   bool              m_onInitTestsExecuted;
   
   void              DisplayResults();
public:
   bool              NotEmpty();
   bool              CanFinish(int currentCandleCount);
   void              FinishUnitTestsuite();
   void              AddUnitTestAsserts(CUnitTestAsserts* ut); // result of old school unit test function
   void              AddUnitTestFunction(UnitTest testFunc); // new school test added
   void              AddUnitTestFunction(int onCandleCount, UnitTest testFunc); // new school add on tick test
   void              AddUnitTestFunction(int onCandleCountA, int onCandleCountB, UnitTest testFunc); // add test in a row of candles
   void              AddSetupFunction(int onCandleCount, Setup setup); // new school on tick test with setup
   void              AddTearDownFunction(int onCandleCount, TearDown tearDown);
   void              AddTearDownFunction(int onCandleCountA, int onCandleCountB, TearDown tearDownFunc);
   void              ExecuteOnInitTests();
   void              ExecuteNewCandleTests(int currentCandleCount);
   void              ExecuteSetup(int currentCandleCount);
   void              ExecuteTeardown(int currentCandleCount);
   void              AddSetupFunction(int onCandleCountA, int onCandleCountB, Setup setupFunc);
                     CUnitTestSuite();
  };


//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CUnitTestSuite::CUnitTestSuite()
  {
   Print(" --- Unit Tests beginning -------------------------------");
  }

//+------------------------------------------------------------------+
//| Method to display test results                                   |
//+------------------------------------------------------------------+
void CUnitTestSuite::DisplayResults()
  {
   CFailedAssert *failedAssert;
   CUnitTestAsserts* asserts  = m_unitTestsAssertList.GetFirstNode();
   int countOfAsserts = m_unitTestsAssertList.Total();
   int total;
   string summary;
   bool summaryState = true;
   
   for(int i = 0; i < countOfAsserts; i++)  // For all unit tests
     {
      total = asserts.TotalFailedTests();

      if(total!=0)  // If there is a failed test
        {
         summaryState = false;
         summary += IntegerToString(i+1) + "F ";
         //Print(asserts.GetTestName()+" failed (candle count: " + IntegerToString(asserts.GetCandleCount())+")");
         for(int j = 0; j < total; j++)
           {
            failedAssert = asserts.GetFailedAssert(j);
            failedAssert.Display();
           }
        }
      else
        {
         summary += " OK ";
         //Print(asserts.GetTestName()+" OK");
        }

      asserts = m_unitTestsAssertList.GetNextNode();
     }

   Print(" --------------------------------------------------------");
   Print(summary);
   Print("Test state: " + (summaryState ? "GREEN" : "RED"));
   if (summaryState)
      ChartSetInteger( 0, CHART_COLOR_BACKGROUND, clrMediumSeaGreen);
   if (!summaryState)
      ChartSetInteger( 0, CHART_COLOR_BACKGROUND, clrTomato);
   ChartRedraw();

   Print(" --------------------------------------------------------");
   Print(" Test algorithms ");
   Print(" --------------------------------------------------------");

   countOfAsserts = m_unitTestsAssertList.Total();
   total=0;
   summaryState = true;
   asserts  = m_unitTestsAssertList.GetFirstNode();

   string lastTestName = asserts.GetTestName();
   int startCount = 1;
   int end = 1;
   string command = "";
   string currentName = asserts.GetTestName();
   int lastFailingCandlecount = 0;

   for(int i = 0; i < countOfAsserts; i++)  // For all unit tests
     {
      currentName = asserts.GetTestName();
      if (currentName!=lastTestName) {
         if (startCount==asserts.GetCandleCount()-1&&startCount==lastFailingCandlecount) {
            startCount = asserts.GetCandleCount();
            lastTestName=currentName;
            continue;
         }
         Print("testSuite.AddUnitTestFunction("+startCount+", "+(asserts.GetCandleCount()-1)+", "+lastTestName+");");
         startCount = asserts.GetCandleCount();
         lastTestName=currentName;
      }
      if (asserts.TotalFailedTests()>0) { 
         Print("testSuite.AddUnitTestFunction("+asserts.GetCandleCount()+", "+asserts.GetCandleCount()+", "+currentName+"); // Failed");
         lastFailingCandlecount = asserts.GetCandleCount();
      } 
      if (i==(countOfAsserts-1)) {
        Print("testSuite.AddUnitTestFunction("+startCount+", "+((asserts.GetCandleCount()))+", "+lastTestName+");");
      }
      asserts = m_unitTestsAssertList.GetNextNode();
     }

   Print(" --------------------------------------------------------");
   Print(" No trades plot ");
   Print(" --------------------------------------------------------");

   countOfAsserts = m_unitTestsAssertList.Total();
   total=0;
   summaryState = true;
   asserts  = m_unitTestsAssertList.GetFirstNode();

   lastTestName = asserts.GetTestName();
   startCount = 1;
   end = 1;
   command = "";
   currentName = asserts.GetTestName();

   for(int i = 0; i < countOfAsserts; i++)  // For all unit tests
     {
      currentName = asserts.GetTestName();
      if (asserts.TotalFailedTests()>0) {
         Print("testSuite.AddUnitTestFunction("+startCount+", "+(asserts.GetCandleCount()-1)+", "+lastTestName+");");
         if (asserts.getTradeActionType()==MQLUNIT_TRADEACTION_BUY)
            Print("testSuite.AddUnitTestFunction("+asserts.GetCandleCount()+", "+asserts.GetCandleCount()+", Test_DoTrading_ShouldPlaceBuyOrder);");
         if (asserts.getTradeActionType()==MQLUNIT_TRADEACTION_SELL)
            Print("testSuite.AddUnitTestFunction("+asserts.GetCandleCount()+", "+asserts.GetCandleCount()+", Test_DoTrading_ShouldPlaceSellOrder);");
         if (asserts.getTradeActionType()==MQLUNIT_TRADEACTION_CLOSEBUY)
            Print("testSuite.AddUnitTestFunction("+asserts.GetCandleCount()+", "+asserts.GetCandleCount()+", Test_DoTrading_ShouldCloseBuyOrder);");
         if (asserts.getTradeActionType()==MQLUNIT_TRADEACTION_CLOSESELL)
            Print("testSuite.AddUnitTestFunction("+asserts.GetCandleCount()+", "+asserts.GetCandleCount()+", Test_DoTrading_ShouldCloseSellOrder);");
         startCount = asserts.GetCandleCount()+1;
         lastTestName=currentName;
      }
      if (i==(countOfAsserts-1)) {
        Print("testSuite.AddUnitTestFunction("+startCount+", "+((asserts.GetCandleCount()))+", "+lastTestName+");");
      }
      asserts = m_unitTestsAssertList.GetNextNode();
     }
  }

//+------------------------------------------------------------------+
//| Add an asserts list to the collection of unit test asserts
//+------------------------------------------------------------------+
void CUnitTestSuite::AddUnitTestAsserts(CUnitTestAsserts* ut)
  {
   m_unitTestsAssertList.Add(ut);
  }

//+------------------------------------------------------------------+
//| Add a unit test function to the suite, that executes OnInit                          
//+------------------------------------------------------------------+
void CUnitTestSuite::AddUnitTestFunction(UnitTest testFunc)
  {
   ArrayResize(m_unitTestFunc_OnInit,ArraySize(m_unitTestFunc_OnInit)+1);
   m_unitTestFunc_OnInit[ArraySize(m_unitTestFunc_OnInit)-1] = testFunc;
  }

//+------------------------------------------------------------------+
//| Add a unit test function to the suite that executes on open of
//| specific new candle
//+------------------------------------------------------------------+
void CUnitTestSuite::AddUnitTestFunction(int onCandleCount, UnitTest testFunc)
  {
   ArrayResize(m_unitTestFunc_OnNewCandle,ArraySize(m_unitTestFunc_OnNewCandle)+1);
   ArrayResize(m_ExecuteOnCandleCount,ArrayRange(m_ExecuteOnCandleCount,0)+1);
   int index = ArraySize(m_unitTestFunc_OnNewCandle)-1;
   m_unitTestFunc_OnNewCandle[index] = testFunc;
   m_ExecuteOnCandleCount[index][0] = onCandleCount;
   m_ExecuteOnCandleCount[index][1] = PENDING;
  }

//+------------------------------------------------------------------+
//| Add unit test functions from index a->b to the suite that executes 
//| on open of specific new candle, before the test cases
//+------------------------------------------------------------------+
void CUnitTestSuite::AddUnitTestFunction(int onCandleCountA, int onCandleCountB, UnitTest testFunc)
  {
     for(int i = onCandleCountA; i <= onCandleCountB; i++) {
        AddUnitTestFunction(i,testFunc);
     }
  }

void CUnitTestSuite::AddSetupFunction(int onCandleCountA, int onCandleCountB, Setup setupFunc)
  {
     for(int i = onCandleCountA; i <= onCandleCountB; i++) {
        AddSetupFunction(i,setupFunc);
     }
  }


//+------------------------------------------------------------------+
//| Add a teardown function for a specific test that executes on open
//| of a specific candle, after the testcases on that candle
//+------------------------------------------------------------------+
void CUnitTestSuite::AddTearDownFunction(int onCandleCount, TearDown tearDown)
  {
   ArrayResize(m_tearDownFunc_OnNewCandle,ArraySize(m_tearDownFunc_OnNewCandle)+1);
   ArrayResize(m_TearDownExecuteOnCandleCount,ArrayRange(m_TearDownExecuteOnCandleCount,0)+1);
   int index = ArraySize(m_tearDownFunc_OnNewCandle)-1;
   m_tearDownFunc_OnNewCandle[index] = tearDown;
   m_TearDownExecuteOnCandleCount[index][0] = onCandleCount;
   m_TearDownExecuteOnCandleCount[index][1] = PENDING;
  }

void CUnitTestSuite::AddTearDownFunction(int onCandleCountA, int onCandleCountB, TearDown tearDownFunc)
  {
     for(int i = onCandleCountA; i <= onCandleCountB; i++) {
        AddTearDownFunction(i,tearDownFunc);
     }
  }


//+------------------------------------------------------------------+
//| Add a setup function for a specific test that executes on open
//| of a specific candle
//+------------------------------------------------------------------+
void CUnitTestSuite::AddSetupFunction(int onCandleCount, Setup setup)
  {
   ArrayResize(m_setupFunc_OnNewCandle,ArraySize(m_setupFunc_OnNewCandle)+1);
   ArrayResize(m_SetupExecuteOnCandleCount,ArrayRange(m_SetupExecuteOnCandleCount,0)+1);
   int index = ArraySize(m_setupFunc_OnNewCandle)-1;
   m_setupFunc_OnNewCandle[index] = setup;
   m_SetupExecuteOnCandleCount[index][0] = onCandleCount;
   m_SetupExecuteOnCandleCount[index][1] = PENDING;
  }


//+------------------------------------------------------------------+
//| Executes the setup functions defined to run on open of specified
//| candle
//+------------------------------------------------------------------+
void CUnitTestSuite::ExecuteSetup(int currentCandleCount)
  {
   for(int i = 0; i < ArraySize(m_setupFunc_OnNewCandle); i++)
     {
      if(currentCandleCount == m_SetupExecuteOnCandleCount[i][0]
         && m_SetupExecuteOnCandleCount[i][1] == PENDING)
        {
         Setup setup = m_setupFunc_OnNewCandle[i];
         setup();
         m_SetupExecuteOnCandleCount[i][1] = EXECUTED;
        }
     }
  }

//+------------------------------------------------------------------+
//| Executes the setup functions defined to run on open of specified
//| candle
//+------------------------------------------------------------------+
void CUnitTestSuite::ExecuteTeardown(int currentCandleCount)
  {
   for(int i = 0; i < ArraySize(m_tearDownFunc_OnNewCandle); i++)
     {
      if(currentCandleCount == m_TearDownExecuteOnCandleCount[i][0]
         && m_TearDownExecuteOnCandleCount[i][1] == PENDING)
        {
         TearDown tearDown = m_tearDownFunc_OnNewCandle[i];
         tearDown();
         m_TearDownExecuteOnCandleCount[i][1] = EXECUTED;
        }
     }
  }

//+------------------------------------------------------------------+
//| Executes the unit tests of the OnInit phase
//+------------------------------------------------------------------+
void CUnitTestSuite::ExecuteOnInitTests(void)
  {
   if (!m_onInitTestsExecuted) {
      for(int i = 0; i < ArraySize(m_unitTestFunc_OnInit); i++)
        {
         UnitTest test = m_unitTestFunc_OnInit[i];
         m_unitTestsAssertList.Add(test());
      }
      m_onInitTestsExecuted = true;
   }
  }

//+------------------------------------------------------------------+
//| Executes unit tests that are supposed to run on open of a 
//| specific candle
//+------------------------------------------------------------------+
void CUnitTestSuite::ExecuteNewCandleTests(int currentCandleCount)
  {
   for(int i = 0; i < ArraySize(m_unitTestFunc_OnNewCandle); i++)
     {
      if(currentCandleCount == m_ExecuteOnCandleCount[i][0]
         && m_ExecuteOnCandleCount[i][1] == PENDING)
        {
         UnitTest test = m_unitTestFunc_OnNewCandle[i];
         CUnitTestAsserts* assert = test();
         assert.SetCandleCount(currentCandleCount);
         m_unitTestsAssertList.Add(assert);
         m_ExecuteOnCandleCount[i][1] = EXECUTED;
        }
     }
  }

//+------------------------------------------------------------------+
//| Find out if test suite is empty
//+------------------------------------------------------------------+
bool CUnitTestSuite::NotEmpty()
  {
   return ArraySize(m_unitTestFunc_OnNewCandle)>0;
  }

//+------------------------------------------------------------------+
//| Find out if there are tests left for candles after current
//| candle count. If no tests are pending, suite can finish.
//+------------------------------------------------------------------+
bool CUnitTestSuite::CanFinish(int currentCandleCount)
  {
   for(int i = 0; i<ArraySize(m_unitTestFunc_OnNewCandle); i++)
     {
      ENUM_TEST_EXEC_STATE status = m_ExecuteOnCandleCount[i][1];
      if(status == PENDING)
        {
         return false;
        }
     }
   return true;
  }

//+------------------------------------------------------------------+
//| Finish the test suite and display results
//+------------------------------------------------------------------+
void CUnitTestSuite::FinishUnitTestsuite()
  {
   Print(" --- Unit Tests end -------------------------------------");
   DisplayResults();

// Clear the lists
   m_unitTestsAssertList.Clear();
   ArrayFree(m_unitTestFunc_OnInit);
   ArrayFree(m_unitTestFunc_OnNewCandle);
   ArrayFree(m_ExecuteOnCandleCount);
   ArrayFree(m_setupFunc_OnNewCandle);
   ArrayFree(m_SetupExecuteOnCandleCount);

  }
//+------------------------------------------------------------------+
