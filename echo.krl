ruleset echo{
    meta {
        shares hello, message
    }
    
    rule hello{
        select when echo hello
        send_directive("say") with
        something = "Hello World"
    }
    
    rule message{
        select when echo message input re#(.*)# setting(msg);
        send_directive("say") with
        something = msg
    }
}