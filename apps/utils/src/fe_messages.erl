%%%-------------------------------------------------------------------
%%% @copyright
%%% COPYRIGHT
%%% @end
%%%-------------------------------------------------------------------
%%% @author Sukumar Yethadka <sbhat7@gmail.com>
%%%
%%% @doc This modules composes replies to the user.
%%%
%%% @end
%%%
%%% @since : 9 Nov 2011 by Bermuda Triangle
%%% @end
%%%-------------------------------------------------------------------
-module(fe_messages).

-include_lib("datatypes/include/game.hrl").

-export([get/2, resp/1, resp/2, resp_unhandled_error/1]).

%%-------------------------------------------------------------------
%% @doc get/2
%%
%% Composes messages for specified return values from the backend
%% @end
%% [@spec get(Result(), Value()) @end]
%%-------------------------------------------------------------------
% User registration
get({register, success}, _Val) ->
    resp("Registration was successful.~n");
get({register, invalid_data}, Error) ->
    case Error of
        nick_already_exists ->
            resp("Nick name not available.~n");
        _ ->
            resp_unhandled_error(Error)
    end;

% User login
get({login, success}, SessionId) ->
    resp("Login was successful. Your session is: \"~p\"~n", [SessionId]);
get({login, invalid_data}, Error) ->
    case Error of
        nick_not_unique ->
            resp("Duplicate nick detected!.~n");
        invalid_login_data ->
            resp("Invalid login data.~n");
        simultaneous_login ->
            resp("Simultaneous login not allowed.~n");
        _ ->
            resp_unhandled_error(Error)
    end;

% Get session user
get({get_session_user, success}, _Val) ->
    resp("");
get({get_session_user, invalid_data}, _Val) ->
    resp("");

% User update
get({update_user, success}, _Val) ->
    resp("User information was successfully updated.~n");
get({update_user, invalid_data}, Error) ->
    case Error of
        does_not_exist ->
            resp("Given user does not exist.~n");
        _ ->
            resp_unhandled_error(Error)
    end;

% Game create
get({create_game, success}, GameId) ->
    resp("Game creation was successful. Your game ID is: \"~p\"~n", [GameId]);
get({create_game, invalid_data}, Error) ->
    case Error of
        _ ->
            resp_unhandled_error(Error)
    end;

% Get game
get({get_game, success}, _Val) ->
    resp("");
get({get_game, invalid_data}, _Val) ->
    resp("");

% Game reconfiguration
get({reconfig_game, success}, _Val) ->
    resp("Game information was successfully updated.~n");
get({reconfig_game, invalid_data}, Error) ->
    case Error of
        game_does_not_exist ->
            resp("The game you are trying to reconfigure does not exist.~n");
        game_started_already ->
            resp("Game cannot be reconfigured once its started.~n");
        not_game_creator ->
            resp("Only the creator of the game can reconfigure it.~n");
        _ ->
            resp_unhandled_error(Error)
    end;

% Game join
get({join_game, success}, _Val) ->
    resp("Join game was successful.~n");
get({join_game, invalid_data}, Error) ->
    case Error of
        country_not_available ->
            resp("Selected country not available.~n");
        user_already_joined ->
            resp("You have already joined this game.~n");
        _ ->
            resp_unhandled_error(Error)
    end;

% Game overview
get({game_overview, success}, _Val) ->
    resp("Game Overview:~n");
get({game_overview, invalid_data}, Error) ->
    case Error of
        user_not_playing_this_game ->
            resp("Only game players can view the game overview.~n");
        _ ->
            resp_unhandled_error(Error)
    end;

% Game order
get({game_order, success}, _Val) ->
    resp("Game order sent successfully:~n~n");
get({game_order, invalid_data}, Error) ->
    case Error of
        game_id_not_exist ->
            resp("The game you are sending orders to, does not exist.~n");
        user_not_playing_this_game ->
            resp("You cannot send orders to a game you are not playing.~n");
        _ ->
            resp_unhandled_error(Error)
    end;

% Invalid session
get({_Cmd, invalid_session}, _Val) ->
    resp("Invalid user session. Please log in to continue.~n");
% Command parse error
get({Cmd, parse_error}, Error) ->
    case Error of
        {error,{required_fields,FieldStrList}} ->
            resp("The command [~p] could not be interpreted correctly:~n"
                 "Required fields: ~p", [Cmd, FieldStrList]);
        {error,{invalid_input, _Val}} ->
            resp("Invalid input for the given command.~n");
        _ ->
            resp("The command[~p] could not be interpreted.~n", [Cmd])
    end;

% Unimplemented command
get({Cmd, _Status}, _Val) ->
    resp("Messages not implemented for ~p.~n", [Cmd]);

% Unknown command
get(unknown_command, _Val) ->
    resp("The provided command is unknown.~n");

% Additional commands
get(game_overview, Val) ->
    game_overview(Val).

%%-------------------------------------------------------------------
%% @doc resp/2
%%
%% Create a formatted response with Data inserted in the Format
%% @end
%% [@spec get(Format(), Data()) @end]
%%-------------------------------------------------------------------
resp(Format, Data) ->
    lists:flatten(io_lib:format(Format, Data)).

%%-------------------------------------------------------------------
%% @doc resp/1
%%
%% Create a formatted response
%% @end
%% [@spec get(Format(), Data()) @end]
%%-------------------------------------------------------------------
resp(Format) ->
    resp(Format, []).

%%-------------------------------------------------------------------
%% @doc resp_unhandled_error/1
%%
%% Get response for unhandled error
%% @end
%% [@spec get(Format(), Data()) @end]
%%-------------------------------------------------------------------
resp_unhandled_error(Error) ->
    resp("Unhandled error.~n~p~n", [Error]).

%% Get game overview in text format
game_overview(#game_overview{} = GOV)->
    {_GameId, Country, Game, Provinces, Units, Orders} =
        data_format:game_overview_to_text(GOV),
    Msg1 = io_lib:format("~nYou are playing as ~s ~nGame Information:~n",
                         [Country]),
    Msg2 = io_lib:format("in game_overview after msg: ~s~n ", [Game]),
    Msg3 = io_lib:format("~nYour provinces:~n~s ~nAll units:~n~s~nYour Orders:~n~p",
                          [Provinces, Units, Orders]),
    lists:flatten(Msg1 ++ Msg2 ++ Msg3).