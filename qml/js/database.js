.pragma library
.import QtQuick.LocalStorage 2.0 as Storage

/*
  Internal functions
 */

var DBVERSION = "0.5"
var _db = null;

function getDatabase()
{
    if ( _db === null ) {
        console.debug( "Opening new connection to the database" );
        _db = Storage.LocalStorage.openDatabaseSync( "WallaRead", "", "WallaRead", 100000000 );
        checkDatabaseStatus( _db );
    }

    return _db;
}

function checkDatabaseStatus( db )
{
    console.debug(db.version);
    if ( db.version === "" ) {
        createLatestDatabase( db );
    }
    // _updateSchema_v* will take care of calling the relevant update methods
    // to bring the database to the latest version
    else if ( db.version === "0.2" ) {
        _updateSchema_v3( db );
    }
    else if ( db.version === "0.3" ) {
        _updateSchema_v4( db )
    } else if ( db.version === "0.4" ) {
        _updateSchema_v5( db );
    }
}

function createLatestDatabase( db )
{
    var version = db.version;

    if ( version !== DBVERSION ) {
        db.transaction(
            function( tx ) {
                tx.executeSql(
                                "CREATE TABLE IF NOT EXISTS articles (" +
                                "id INTEGER, " +
                                "created TEXT, " +
                                "updated TEXT, " +
                                "mimetype TEXT, " +
                                "language TEXT, " +
                                "readingTime INTEGER DEFAULT 0, " +
                                "url TEXT, " +
                                "domain TEXT, " +
                                "archived INTEGER DEFAULT 0, " +
                                "starred INTEGER DEFAULT 0, " +
                                "title TEXT, " +
                                "previewPicture BLOB, " +
                                "content TEXT, " +
                                "PRIMARY KEY(id)" +
                                ")"
                             );

                db.changeVersion( version, DBVERSION );
            }
        );
    }
}

function resetDatabase()
{
    var db = getDatabase();
    var version = db.version;

    db.transaction(
        function( tx ) {
            tx.executeSql( "DROP TABLE IF EXISTS servers" );
            tx.executeSql( "DROP TABLE IF EXISTS articles" );
            db.changeVersion( version, "" );
            createLatestDatabase( db );
        }
    );
}

function _updateSchema_v3( db )
{
    db.transaction(
        function( tx ) {
            tx.executeSql(
                            "CREATE TABLE IF NOT EXISTS articles_next (" +
                            "id INTEGER, " +
                            "server INTEGER REFERENCES servers(id), " +
                            "created TEXT, " +
                            "updated TEXT, " +
                            "mimetype TEXT, " +
                            "language TEXT, " +
                            "readingTime INTEGER DEFAULT 0, " +
                            "url TEXT, " +
                            "domain TEXT, " +
                            "archived INTEGER DEFAULT 0, " +
                            "starred INTEGER DEFAULT 0, " +
                            "title TEXT, " +
                            "previewPicture BLOB, " +
                            "content TEXT, " +
                            "PRIMARY KEY(id, server)" +
                            ")"
                         );
            tx.executeSql( "INSERT INTO articles_next SELECT * FROM articles" );
            tx.executeSql( "DROP TABLE articles" );
            tx.executeSql( "ALTER TABLE articles_next RENAME TO articles" );

            db.changeVersion( db.version, "0.3" );
            _updateSchema_v4( db )
        }
    );
}

function _updateSchema_v4( db )
{
    db.transaction(
        function( tx ) {
            tx.executeSql(
                            "CREATE TABLE IF NOT EXISTS servers_next (" +
                            "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
                            "name TEXT NOT NULL, " +
                            "url TEXT NOT NULL, " +
                            "user TEXT NOT NULL, " +
                            "password TEXT NOT NULL, " +
                            "clientId TEXT NOT NULL, " +
                            "clientSecret TEXT NOT NULL, " +
                            "lastSync INTEGER DEFAULT 0," +
                            "fetchUnread INTEGER DEFAULT 0" +
                            ")"
                         );
            tx.executeSql( "INSERT INTO servers_next SELECT * FROM servers" );
            tx.executeSql( "DROP TABLE servers" );
            tx.executeSql( "ALTER TABLE servers_next RENAME TO servers" );

            db.changeVersion( db.version, "0.4" );
        }
    );
}

function _updateSchema_v5( db )
{
    db.transaction(
        function( tx ) {
            tx.executeSql(
                            "CREATE TABLE IF NOT EXISTS articles_next (" +
                            "id INTEGER, " +
                            "created TEXT, " +
                            "updated TEXT, " +
                            "mimetype TEXT, " +
                            "language TEXT, " +
                            "readingTime INTEGER DEFAULT 0, " +
                            "url TEXT, " +
                            "domain TEXT, " +
                            "archived INTEGER DEFAULT 0, " +
                            "starred INTEGER DEFAULT 0, " +
                            "title TEXT, " +
                            "previewPicture BLOB, " +
                            "content TEXT, " +
                            "PRIMARY KEY(id)" +
                            ")"
                         );
            tx.executeSql( "INSERT INTO articles_next SELECT id, created, updated, mimetype, language, readingTime, url, domain, archived, starred, title, previewPicture, content FROM articles" );
            tx.executeSql( "DROP TABLE articles" );
            tx.executeSql( "ALTER TABLE articles_next RENAME TO articles" );

            db.changeVersion( db.version, "0.5" );
        }
    );
}
