
-module(clean_release). 
-export([clean_release/1]). 

clean_release([ReleaseName]) -> 
    RelFile = atom_to_list(ReleaseName) ++ ".rel",
    case file:consult(RelFile) of
	{ok, [{release, {RelName, RelVsn}, ErtsSpec, ReleaseSpecs}]} -> do_rest(RelFile, ReleaseSpecs);
	{error, Reason} -> io:format("ERROR - Could not find file ~s~n", [RelFile]), exit(Reason)
    end,
    os:cmd("cd ../;rm -rf " ++ string:strip(os:cmd("basename /Users/martinjlogan/work/erlware-projects/otp-base/tools"))).
	     
do_rest(RelFile, ReleaseSpecs) ->
    io:format("Finding Orphans in ~p among current release specs ~p~n", [RelFile, ReleaseSpecs]),
    {ok, FileNameList}    = file:list_dir("../"),
    Dirs = [FileName || FileName <- FileNameList, filelib:is_dir("../" ++ FileName)] --
	   [string:strip(os:cmd("basename /Users/martinjlogan/work/erlware-projects/otp-base/tools"), right, $\n)],
    BigListOfReleaseSpecs = lists:foldl(fun(Dir, Acc) -> 
						OtherRelFile = "../" ++ Dir ++ "/" ++ RelFile,
						io:format("Checking external release file ~p~n", [OtherRelFile]),
						case file:consult(OtherRelFile) of
						    {ok, [{release, {RelName, RelVsn}, ErtsSpec, ReleaseSpecs_}]} -> 
							Acc ++ ReleaseSpecs_;
						    _  -> 
							Acc
						end end, [], Dirs),
    Orphans = ReleaseSpecs -- BigListOfReleaseSpecs,
    io:format("Removing orphan release specs ~p from ../../lib ~n", [Orphans]),
    lists:foreach(fun(Orphan) -> 
			  os:cmd("rm -rf ../../lib/" ++ atom_to_list(element(1, Orphan)) ++ "-" ++ element(2, Orphan)) 
		  end, Orphans).

