-module(ctr_callee_subscription).

-include("ct_router.hrl").

-export([ list/3,
          get/3,
          subscriber/3,
          subscriber_count/3
        ]).


list(_Args, _Kw, Realm) ->
    {ok, Subscriptions} = ctr_broker_data:get_subscription_list(Realm),

    Separator = fun(#ctr_subscription{ id = Id, match = exact },
                    {ExactList, PrefixList, WildcardList}) ->
                        { [ Id | ExactList ], PrefixList, WildcardList };
                   (#ctr_subscription{ id = Id, match = prefix },
                    {ExactList, PrefixList, WildcardList}) ->
                        { ExactList, [ Id | PrefixList], WildcardList };
                   (#ctr_subscription{ id = Id, match = wildcard },
                    {ExactList, PrefixList, WildcardList}) ->
                        { ExactList, PrefixList, [ Id | WildcardList ] }
                end,
    {E, P, W} = lists:foldl(Separator, {[], [], []}, Subscriptions),
    { [#{exact => E, prefix => P, wildcard => W}], undefined}.

get([Id], _Kw, Realm) ->
    Result = ctr_broker_data:get_subscription(Id, Realm),
    handle_get_result(Result).

handle_get_result({ok, Subscription}) ->
    Keys = [id, created, match, uri],
    SubscriptionMap = ctr_subscription:to_map(Subscription),
    { [maps:with(Keys, SubscriptionMap) ], undefined};
handle_get_result(_) ->
    throw(no_such_registration).

subscriber([Id], _Kw, Realm) ->
    Result = get_subscription_map(Id, Realm),
    {[to_subscriber_list(Result)], undefined}.

subscriber_count([Id], _Kw, Realm) ->
    Result = get_subscription_map(Id, Realm),
    {[length(to_subscriber_list(Result))], undefined}.


get_subscription_map(Id, Realm) ->
    Result = ctr_broker_data:get_subscription(Id, Realm),
    maybe_convert_to_map(Result).

maybe_convert_to_map({ok, Subscription}) ->
    {ok, ctr_subscription:to_map(Subscription)};
maybe_convert_to_map(Error) ->
    Error.


to_subscriber_list({ok, #{subs := Subs}}) ->
    Subs;
to_subscriber_list(_) ->
    throw(no_such_registration).