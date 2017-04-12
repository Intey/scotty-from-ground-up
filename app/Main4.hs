--- Demonstrate handling routes only if previous one

import qualified Control.Monad.Trans.State.Strict as ST
import qualified Control.Monad.Trans.Except as Exc

-- State Monad
-- How to use a State Monad

type Middleware = String -> Maybe String
type Route = Middleware -> Middleware

data AppState = AppState { middlewares:: [Route]}

type ActionError = String

type AppStateT = ST.State AppState

type ActionT = Exc.ExceptT ActionError Maybe String

add_middleware' mf s@(AppState {middlewares = mw}) = s {middlewares = mf:mw}

middleware_func1 input = Nothing --Just $ input ++ " middleware1 called\n"

middleware_func2 input = Just $ input ++ " middleware2 called\n"

--middlware_func_buggy input = Exc.throwError "test"

middleware_func3 input = Just $ input ++ " middleware3 called\n"

--handler s = Just "There was an error returned: " ++ s

route :: Middleware -> (String -> Bool) -> Route
route mw pat mw1 input_string =
  let tryNext = mw1 input_string in
  if pat input_string
  then
    maybe tryNext mw $ return input_string
  else
    tryNext

add_middleware mf pat = ST.modify $ \s -> add_middleware' (route mf pat) s

cond condition_str = f where
  f i = i == condition_str 

myApp :: AppStateT ()
myApp = do
  add_middleware middleware_func1 (\s -> s == "middleware1")
  add_middleware middleware_func2 (\s -> s == "middleware2")
  add_middleware middleware_func3 (\s -> s == "middleware3")

runMyApp initial_string my_app =
  let s = ST.execState my_app $ AppState { middlewares = []}
      output = foldl (flip ($)) initial_string (middlewares s) in
  output

main = do
  print $ "Starting demonstration of middlewares"
  let x1 = runMyApp (\x-> Just "default middlware called") myApp "middleware2"
  case x1 of
    Just x1 -> print x1
    Nothing -> print "Error"
