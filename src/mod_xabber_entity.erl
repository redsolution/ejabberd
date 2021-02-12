%%%-------------------------------------------------------------------
%%% File    : mod_xabber_entity.erl
%%% Author  : Andrey Gagarin <andrey.gagarin@redsolution.com>
%%% Purpose : Store information about entities
%%% Created : 16 November 2020 by Andrey Gagarin <andrey.gagarin@redsolution.com>
%%%
%%%
%%% xabberserver, Copyright (C) 2007-2020   Redsolution OÜ
%%%
%%% This program is free software; you can redistribute it and/or
%%% modify it under the terms of the GNU General Public License as
%%% published by the Free Software Foundation; either version 2 of the
%%% License, or (at your option) any later version.
%%%
%%% This program is distributed in the hope that it will be useful,
%%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
%%% General Public License for more details.
%%%
%%% You should have received a copy of the GNU General Public License along
%%% with this program; if not, write to the Free Software Foundation, Inc.,
%%% 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
%%%
%%%----------------------------------------------------------------------
-module(mod_xabber_entity).
-author("andrey.gagarin@redsolution.ru").
-include("ejabberd_sql_pt.hrl").
-compile([{parse_transform, ejabberd_sql_pt}]).
%% API
-export([is_exist/2, is_exist_anywhere/2, get_entity_type/2]).

is_exist_anywhere(LUser, LServer) ->
  case ejabberd_auth:user_exists(LUser, LServer) of
    true ->
      true;
    _ ->
      is_exist(LUser, LServer)
  end.

is_exist(LUser, LServer) ->
  is_exist(LUser, LServer , ejabberd_sql:use_new_schema()).

is_exist(LUser, LServer, true) ->
  case ejabberd_sql:sql_query(
    LServer,
    [<<"select localpart from
    (
    (select localpart,server_host from groupchats)
    UNION
    (select localpart,server_host from channels)
    ) as t
    where localpart = '">>,LUser,<<"' and server_host ='">>,ejabberd_sql:escape(LServer),<<"'">>]) of
    {selected,_TableRow,[]} ->
      false;
    _ ->
      true
  end;
is_exist(LUser, LServer, _Schema) ->
case ejabberd_sql:sql_query(
  LServer,
  [<<"select localpart from
    (
    (select localpart from groupchats)
    UNION
    (select localpart from channels)
    ) as t
    where localpart ='">>,ejabberd_sql:escape(LUser),<<"'">>]) of
  {selected,_TableRow,[]} ->
    false;
  _ ->
    true
end.

is_group(LUser, LServer) ->
  case ejabberd_sql:sql_query(
    LServer,
    ?SQL("select @(localpart)s
    from groupchats where localpart=%(LUser)s and %(LServer)H")) of
    {selected, Info} when length(Info) > 0 ->
      true;
    _ ->
      false
  end.

is_channel(LUser, LServer) ->
  case ejabberd_sql:sql_query(
    LServer,
    ?SQL("select @(localpart)s
    from channels where localpart=%(LUser)s and %(LServer)H")) of
    {selected, Info} when length(Info) > 0 ->
      true;
    _ ->
      false
  end.

get_entity_type(LUser, LServer) ->
  case is_group(LUser, LServer) of
    true ->
      group;
    _ ->
      case is_channel(LUser, LServer) of
        true -> channel;
        _ -> user
      end
  end.