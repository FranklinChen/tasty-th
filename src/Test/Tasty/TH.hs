-----------------------------------------------------------------------------
--
-- Module      :  MainTestGenerator
-- Copyright   :  
-- License     :  BSD4
--
-- Maintainer  :  Benno Fünfstück
-- Stability   :  
-- Portability :  
--
-- 
-----------------------------------------------------------------------------
{-# OPTIONS_GHC -XTemplateHaskell #-}

module Test.Tasty.TH 
  ( testGroupGenerator
  , defaultMainGenerator
  ) where

import Language.Haskell.TH
import Language.Haskell.Extract 

import Test.Tasty

-- | Generate the usual code and extract the usual functions needed in order to run HUnit/Quickcheck/Quickcheck2.
-- All functions beginning with case_, prop_ or test_ will be extracted.
-- 
-- > {-# OPTIONS_GHC -fglasgow-exts -XTemplateHaskell #-}
-- > module MyModuleTest where
-- > import Test.HUnit
-- > import MainTestGenerator
-- >
-- > main = $(defaultMainGenerator)
-- >
-- > case_Foo = do 4 @=? 4
-- >
-- > case_Bar = do "hej" @=? "hej"
-- >
-- > prop_Reverse xs = reverse (reverse xs) == xs
-- > where types = xs :: [Int]
-- >
-- > test_Group =
-- > [ testCase "1" case_Foo
-- > , testProperty "2" prop_Reverse
-- > ]
-- 
-- will automagically extract prop_Reverse, case_Foo, case_Bar and test_Group and run them as well as present them as belonging to the testGroup 'MyModuleTest' such as
--
-- > me: runghc MyModuleTest.hs
-- > MyModuleTest:
-- > Reverse: [OK, passed 100 tests]
-- > Foo: [OK]
-- > Bar: [OK]
-- > Group:
-- > 1: [OK]
-- > 2: [OK, passed 100 tests]
-- >
-- > Properties Test Cases Total
-- > Passed 2 3 5
-- > Failed 0 0 0
-- > Total 2 3 5
defaultMainGenerator :: ExpQ
defaultMainGenerator =
  [| defaultMain $ testGroup $(locationModule) $ $(propListGenerator) ++ $(caseListGenerator) ++ $(testListGenerator)|]

-- | Generate the usual code and extract the usual functions needed for a testGroup in HUnit/Quickcheck/Quickcheck2.
--   All functions beginning with case_, prop_ or test_ will be extracted.
--  
--   > -- file SomeModule.hs
--   > fooTestGroup = $(testGroupGenerator)
--   > main = defaultMain [fooTestGroup]
--   > case_1 = do 1 @=? 1
--   > case_2 = do 2 @=? 2
--   > prop_p xs = reverse (reverse xs) == xs
--   >  where types = xs :: [Int]
--   
--   is the same as
--
--   > -- file SomeModule.hs
--   > fooTestGroup = testGroup "SomeModule" [testProperty "p" prop_1, testCase "1" case_1, testCase "2" case_2]
--   > main = defaultMain [fooTestGroup]
--   > case_1 = do 1 @=? 1
--   > case_2 = do 2 @=? 2
--   > prop_1 xs = reverse (reverse xs) == xs
--   >  where types = xs :: [Int]
testGroupGenerator :: ExpQ
testGroupGenerator =
  [| testGroup $(locationModule) $ $(propListGenerator) ++ $(caseListGenerator) ++ $(testListGenerator) |]

listGenerator :: String -> String -> ExpQ
listGenerator beginning funcName =
  functionExtractorMap beginning (applyNameFix funcName)

propListGenerator :: ExpQ
propListGenerator = listGenerator "^prop_" "testProperty"

caseListGenerator :: ExpQ
caseListGenerator = listGenerator "^case_" "testCase"

testListGenerator :: ExpQ
testListGenerator = listGenerator "^test_" "testGroup"

-- | The same as
--   e.g. \n f -> testProperty (fixName n) f
applyNameFix :: String -> ExpQ
applyNameFix n =
  do fn <- [|fixName|]
     return $ LamE [VarP (mkName "n")] (AppE (VarE (mkName n)) (AppE (fn) (VarE (mkName "n"))))

fixName :: String -> String
fixName name = replace '_' ' ' $ drop 5 name

replace :: Eq a => a -> a -> [a] -> [a]
replace b v = map (\i -> if b == i then v else i)
