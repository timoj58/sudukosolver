-module(sudukosolver).
-compile(export_all).

main() ->
 File = "suduko.txt",
 {ok,Bin} = file:read_file(File),

 Board = parse_board(Bin),
 test_board(Board),

 GridMap = create_grid_map(Board, 1, []),
 %%good bit. get our workable stacks.
 Rows = get_stacks(lists:seq(1,9), "Rows", GridMap, []),
 Columns = get_stacks(lists:seq(1,9), "Columns", GridMap, []),
 Grids = get_3by3_grids(2, GridMap, []),
 print(Columns),
 pretty_print(GridMap),
 solve(Rows, Columns, Grids, []).
 %%pretty_print(GridMap).

%%load the board 
 parse_board(Bin) when is_binary(Bin) -> parse_board(binary_to_list(Bin));
 parse_board(Str) when is_list(Str) -> [list_to_integer(X)||X <- string:tokens(Str,"\r\n\t ")].

%% creates our tuples per item
create_grid_map([],_, Acc) -> lists:reverse(Acc);
create_grid_map([B1, B2, B3, B4, B5, B6, B7, B8, B9|Rest], Y, Acc) ->
 List = [B1, B2, B3, B4, B5, B6, B7, B8, B9],
 create_grid_map(Rest, Y+1, create_row(List, 1, Y, Acc)). 

create_row([],_,_,Acc) -> Acc;
create_row([R|T], X, Y, Acc) ->
  create_row(T, X+1, Y, [{{X,Y}, R, is_fixed(R)} | Acc]).
 
is_fixed(V) -> 
 if V == 0 -> "false";
  true -> "true"
  end.

%%helper function to stacks.
get_stacks([],_,_,Stacks) -> lists:reverse(Stacks);
get_stacks([C|T],Type, Map, Stacks) ->
 if Type == "Columns" ->  get_stacks(T, Type, Map, [get_stack({C, -1}, Map,[])|Stacks]);
    Type == "Rows" ->  get_stacks(T,Type, Map, [get_stack({-1, C}, Map,[])|Stacks]);
    true -> erlang:error("non supported type")
 end.

get_stack(_,[], Stack) -> lists:reverse(Stack);
get_stack(Exp, [Map|T], Stack) ->
 Resp = contains_value(Map,Exp),
 if Resp == true ->
  get_stack(Exp, T, [Map|Stack]);
 true -> get_stack(Exp, T, Stack)
 end. 

contains_value({{X,Y},_,_}, {Col,Row}) ->
 if X == Col -> true;
    Y == Row -> true;
 true -> false
 end. 

%% help function to get our 3by3 grids
get_3by3_grids(11, _, Stack) -> lists:reverse(Stack);
get_3by3_grids(X, Board, Stack) ->
 get_3by3_grids(X+3, Board, [get_grids(X,8, Board, []), get_grids(X,5, Board, []), get_grids(X,2, Board, []) | Stack]).

get_grids(_,_, [], Stack) -> lists:reverse(Stack);
get_grids(X, Y, [Board|T], Stack) ->
 Resp = find_3by3_element(X, Y, Board),
 if  Resp == true -> get_grids(X, Y, T, [ Board |Stack]);
  true -> get_grids(X,Y,T, Stack)
 end.


%% need to find 3by 3.
find_3by3_element(StartX,StartY,{{X,Y},_,_}) ->
 
 if X == StartX, Y == StartY -> true;
    X == StartX+1, Y == StartY -> true;
    X == StartX-1, Y == StartY -> true;
    X == StartX, Y == StartY+1 -> true;
    X == StartX, Y == StartY-1 -> true;
    X == StartX-1, Y == StartY+1 -> true;
    X == StartX+1, Y == StartY-1 -> true;
    X == StartX+1, Y == StartY+1 -> true;
    X == StartX-1, Y == StartY-1 -> true;
    true -> false
 end. 



%% filter grids by row
filter_grids_by_row([], _, Filter) -> lists:reverse(Filter);
filter_grids_by_row([CellX, CellY, CellZ|Tail], Grids, Filter) ->
  %% to review seems to work of sorts. wont work for the grids in tail...fix later on.
 filter_grids_by_row(Tail, Grids, [filter_by_cell(Grids, CellX, [])|Filter]).

%% filter list of lists by a cell
filter_by_cell([], _, Filter) -> lists:reverse(Filter);
filter_by_cell([List|Tail], Cell, Filter) ->
  Res = lists:any(fun(X) -> X == Cell end,List),
  if Res == true ->  filter_by_cell(Tail, Cell, List);
  true -> filter_by_cell(Tail, Cell, Filter) 
  end.

%% logic section.
solve(Rows, Columns, Grids, Solution) -> 
 %% functions required. Firstly we need an exit case.
 %% test out row 1.. and its matching columns, and grids...then go crazy with the full board.
 %% for 1 row, all columns are applicable.  And vice versa, grids are only those grids that contain the row elements
 Checking = test_solution(hd(Rows), Columns, filter_grids_by_row(hd(Rows), Grids, []),  []).

%% test row solution
test_solution([],_,_, Solution) -> lists:reverse(Solution);
test_solution([Row|T], Columns, Grids, Solution) -> 
 {{X,Y},V,F} = Row,
 if F == "false", V == 0 -> 
   Unique = get_unique_value(lists:seq(1,9),Solution,
                 filter_by_cell(Columns, Row, []),
                 filter_by_cell(Grids, Row, []), {{X,Y},V,F}),
   %% given this we now need to check against our column....
   test_solution(T,Columns, Grids, [Unique|Solution]); 
   true -> test_solution(T, Columns, Grids, [Row|Solution])
 end.

%% get a unique value to the solution we need to add our unique column and grid (we can only be in one of each).
get_unique_value([],_,_,_,NewValue) -> NewValue;
get_unique_value([Value|Rest], Solution, Column, Grid, NewValue) -> 
 {{X,Y},V,F} = NewValue,
 Res = lists:any(fun({{X,Y},V,F}) -> V == Value end, lists:append(lists:append(Column, Solution),Grid)),
   if Res == false -> 
   get_unique_value(Rest, Solution, Column, Grid, {{X,Y},Value,F});
   true -> get_unique_value(Rest, Solution, Column, Grid, NewValue)
  end.

%% some basic tests to ensure board is valid before starting
test_board(Board) when length(Board) == 81 ->  "Ok";
test_board(Board) when length(Board) < 81 -> erlang:error("Board too small");
test_board(Board) when length(Board) > 81 -> erlang:error("Board too large").
   
%% print function for testing
print([]) ->  io:format("End ~n", []);
print([GridMap|T]) ->
 sub_print(GridMap),
 print(T).
%% List = GridMap,
%%{{X,Y},V,F} = hd(GridMap),
%% io:format("Value is ~w For Cell ~w  ~w , fixed = ~s ~n", [V,X,Y,F]),
%% print(T). 

sub_print([]) ->  io:format("End ~n", []);
sub_print([H|T]) ->
 {{X,Y},V,F} = H,
 io:format("Value is ~w For Cell ~w  ~w , fixed = ~s ~n", [V,X,Y,F]),
 sub_print(T).

%% pretty print
pretty_print([]) -> io:format(" ",[]);
pretty_print([GridMap|T]) when length(T) == 80  ->
 {{_,_},V,F} = GridMap,
 io:format("------------------------------------ ~n",[]),
 if F == "true" -> io:format("| ~w ", [V]);
  true -> io:format("|  ", [])
  end,   
 pretty_print(T);
pretty_print([GridMap|T]) when length(T) rem 9 == 0  ->
 {{_,_},V,F} = GridMap,
 if F == "true" -> io:format("| ~w | ~n------------------------------------ ~n", [V]);
 true ->   io:format("|   | ~n------------------------------------ ~n", [])
 end, 
 pretty_print(T);
pretty_print([GridMap|T]) ->
 {{_,_},V,F} = GridMap,
 if F == "true" -> io:format("| ~w ", [V]);
 true -> io:format("|   ", [])
 end,   
 pretty_print(T).
 





   









