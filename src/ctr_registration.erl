-module(ctr_registration).

-include_lib("ctr_data/include/ctr_data.hrl").

-export([
         to_map/1,

         add/3,
         remove/2,

         get_id/1,
         get_callees/1,

         list_of_realm/1,
         lookup/3,
         match/2,
         get/2,

         separated_list_of_realm/1

        ]).


add(Procedure, Match, Session) ->
    SessionId = cta_session:get_id(Session),
    Realm = cta_session:get_realm(Session),
    ctr_data:add_registration(Procedure, Match, SessionId, Realm).

get_id(#ctr_registration{id = Id}) ->
    Id.

to_map(#ctr_registration{id = Id, created = Created, procedure = Uri,
                         match = Match, invoke = Invoke,
                         callee_sess_ids = Callees }) ->
    #{id => Id,
      created => iso8601:format(Created),
      uri => Uri,
      match => Match,
      invoke => Invoke,
      callees => Callees}.

get_callees(#ctr_registration{ callee_sess_ids = Callees } ) ->
    Callees.

get(RegistrationId, Realm) ->
    ctr_data:get_registration(RegistrationId, Realm).

lookup(Procedure, Options, Realm) ->
    ctr_data:lookup_registration(Procedure, Options, Realm).

match(Procedure, Realm) ->
    ctr_data:match_registration(Procedure, Realm).

list_of_realm(Realm) ->
    ctr_data:list_registrations(Realm).

separated_list_of_realm(Realm) ->
    {ok, Registrations} = list_of_realm(Realm),
    Separator = fun(#ctr_registration{ id = Id, match = exact },
                    {ExactList, PrefixList, WildcardList}) ->
                        { [ Id | ExactList ], PrefixList, WildcardList };
                   (#ctr_registration{ id = Id, match = prefix },
                    {ExactList, PrefixList, WildcardList}) ->
                        { ExactList, [ Id | PrefixList], WildcardList };
                   (#ctr_registration{ id = Id, match = wildcard },
                    {ExactList, PrefixList, WildcardList}) ->
                        { ExactList, PrefixList, [ Id | WildcardList ] }
                end,
    {E, P, W} = lists:foldl(Separator, {[], [], []}, Registrations),
    #{exact => E, prefix => P, wildcard => W}.


remove(RegistrationId, Session) ->
    SessionId = cta_session:get_id(Session),
    Realm = cta_session:get_realm(Session),
    ctr_data:remove_registration(RegistrationId, SessionId, Realm).
