# auth

*Production-worthy, generic authentication system. Currently implements both password-based and RSA-key-based authentication calls.*
*Coming Soon: Two Factor Authentication*

### Dependencies

**auth** requires

- [erlang](http://www.erlang.org/) (duh)
- [python 2.x](http://www.python.org/getit/releases/2.7/) (comes standard with Debian linux, available pretty much everywhere)
- [erlport](http://erlport.org/) (available through [setuptools](http://pypi.python.org/pypi/setuptools); if you're on Debian, you can run `make install` as root, the project Makefile includes everything you'll need)

**auth** depends on 

- [erlsha2](https://github.com/vinoski/erlsha2) (an implementation of the SHA-2 cryptographic hashing functions in Erlang/C) and 
- [common](https://github.com/Inaimathi/common) (a still very small set of Erlang utility functions I use in a bunch of different places. At this point it just glosses over some odd bits of the `mnesia` api, and provides basic utility functions).

### NOTE

The goal of this module is to be a production-ready user system, but it's still in the early-ish stages of development. The following is documentation about what modules *currently* do. There are still some inconsitancies, and things I **know** will be changing shortly. Notably:

- Some functions error on improper input, others return `false` or `already_exists`. That should be consistent across the system, at least.
- `rsa_auth:verify/3` returns `true` instead of a user record on success
- a lot of the `groups` functions return records rather than pared down representations

### groups

    list/0 () -> [Group | Rest]

Returns a list of top-level groups (groups that have no parent groups).

    list/1 () -> [Group | Rest]
    
Returns a list of groups with the specified parents.

    get/1 (Id) -> Group || false
    
Returns a group with the specified ID. Returns `false` if no group exists with the given ID.

    add/1 (GroupName) -> GroupId
    
Adds a new group with the name `GroupName`. Note that unlike user names, group names need not be unique. All group operations that require unique results should address groups by ID rather than by name.

    add/2 (GroupName, ParentId) -> GroupId

Adds a new subgroup to `ParentId` named `GroupName`.

    rename/2 (GroupId, NewName) -> ok || error
    
Renames the specified group. Errors if nonexistant group is specified

    add_to (GroupId, {user, ChildId} || {group, ChildId}) -> ok || false || error

Adds a subgroup or user to the specified group. Errors if either parent or child don't exist. Returns false if either parent or child is already related to the other.

    remove_from(GroupId, {user, ChildId} || {group, ChildId}) -> ok || false || error

Removes a subgroup or user from the specified group. Errors if either parent or child don't exists. Returns `false`, but does nothing if the specified child is not already a child of the parent.

### users

    list/0 () -> [{user.id, user.username, user.groups} | ...]
    
Returns a list of users in the system.

    register/2 (Username, Password) -> {user.id, user.username, []} || already_exists
    
Registers a given user, or returns `already_exists`.

    get/1 (UserId || Username) -> {user.id, user.username, user.groups} || false
    
Returns the user record, or `false` if nonexistant user is specified.

    change_password/2 (Username, NewPassword) -> ok || error

Changes the given users password, or errors if nonexistant user is specified.

    auth/2 (Username, Password) -> {user.id, user.username, user.groups} || false
    
Returns the user record if proper authentication information is given. Returns `false` with a two-second delay if either the username or password are incorrect.

### rsa_auth

    list/0 () -> [{UserId, PubKey} | ...]

lists all user_id/pubkey pairs

    get_key/1 (UserId) -> PubKey 

returns a given users' key, or 'false' if that user has no key

    new_key/2 (UserId, Pubkey) ->  PubKey || already_exists

Sets the specified users' public key or returns `already_exists`.

    change_key/2 (UserId, Pubkey) -> PubKey || false 

Changes the key for an existing user, returns `false` if the specified user doesn't exist.

    validate_keystring/2 (KeyString) -> true || false

Takes a string and returns `true` if it is a valid RSA public key. Returns `false` otherwise.
    
    gen_secret/2 (UserId, Meta) -> {Secret, Sig}

Generates a new secret for the specified user with specified metadata (usually IP and user agent). Returns the secret, and a corresponding signature generated by the servers' private key.

    verify/3 (UserId, Meta, Sig) -> true || false

Verifies a given Meta/Signature combination for a given user. Returns `true` if it checks out, `false` otherwise. This should probably return the user record (like `users:auth/2`) in the event of a pass.

### test.erl

    run/1 ([Username, Groupname]) -> test output (hopefully no errors)
    
This module assumes it's running on a fresh database, and requires a unique `Username` and `Groupname`, otherwise odd errors will show up. Run it by using `make test` rather than manually (the `make` rule creates a fresh mnesia database and deletes it when its done).
