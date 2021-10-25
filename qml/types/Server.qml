/*
 * WallaRead - A Wallabag 2+ client for SailfishOS
 * © 2016 Grégory Oestreicher <greg@kamago.net>
 *
 * This file is part of WallaRead.
 *
 * WallaRead is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * WallaRead is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with WallaRead.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

import QtQuick 2.0
import harbour.wallaread 1.0

import "../js/WallaBase.js" as WallaBase

Item {
    id: server

    property string name
    property int lastSync: 0
    property string accessToken
    property string refreshToken
    property string tokenType
    property int tokenExpiry: 0
    property bool fetchUnread: false

    signal articlesDownloaded( var list )
    signal connected
    signal error( string message )

    HttpRequester {
        id: httpRequester
    }

    function connect( cb ) {
        var now = Math.floor( (new Date).getTime() / 1000 )
        if ( tokenExpiry <= now ) {
            WallaBase.connectToServer(
                settings,
                function( props, err ) {
                    onConnectionDone( props, err, cb )
                }
            )
        }
        else {
            cb( null );
        }
    }

    function onConnectionDone( props, err, cb ) {
        if ( err === null ) {
            console.debug( "Successfully connected to server " + props.url )
            accessToken = props.access_token
            refreshToken = props.refresh_token
            tokenType = props.token_type
            tokenExpiry = Math.floor( (new Date).getTime() / 1000 ) + props.expires_in
        }

        cb( err )
    }

    function isConnected() {
        return tokenExpiry > Math.floor( (new Date).getTime() / 1000 )
    }

    function syncDeletedArticles( cb ) {
        connect(
            function( err ) {
                if ( err !== null ) {
                    error( qsTr( "Failed to connect to server: " ) + err )
                    cb()
                }
                else {
                    WallaBase.syncDeletedArticles( { token: accessToken, url: settings.base_url }, function() { cb(); } )
                }
            }
        )
    }

    // No need for a callback here as the articlesDownloaded() signal will
    // be emitted if there are any changes.
    function getUpdatedArticles() {
        connect(
            function( err ) {
                if ( err !== null ) {
                    error( qsTr( "Failed to connect to server: " ) + err)
                    articlesDownloaded( [] )
                }
                else {
                    console.debug( "Downloading articles changes since last sync" )
                    var props = { url: settings.base_url, since: lastSync, accessToken: accessToken, archive: fetchUnread ? 1 : 0 }
                    WallaBase.downloadArticles( props, onGetUpdatedArticlesDone )
                }
            }
        )
    }

    function onGetUpdatedArticlesDone( articles, err ) {
        var ret = new Array;

        if ( err !== null ) {
            error( qsTr( "Failed to download articles: " ) + err )
        }
        else {
            console.debug( "Retrieved " + articles.length + " new/updated articles" )

            for ( var i = 0; i < articles.length; ++i ) {
                var current = articles[i];
                var article = {
                    id: current.id,
                    created: current.created_at,
                    updated: current.updated_at,
                    mimetype: current.mimetype,
                    language: current.language,
                    readingTime: current.reading_time,
                    url: current.url,
                    domain: current.domain_name,
                    archived: current.is_archived,
                    starred: current.is_starred,
                    title: current.title,
                    previewPicture: current.previewPicture,
                    content: current.content
                }
                WallaBase.saveArticle( article )
                ret.push( article )
            }
        }

        articlesDownloaded( ret )
    }

    function uploadArticle( articleUrl, cb ) {
        connect(
            function( err ) {
                if ( err !== null ) {
                    error( qsTr( "Failed to connect to server: " ) + err )
                    cb( false )
                }
                else {
                    console.debug( "Sending a new article" )
                    var props = { url: settings.base_url, token: accessToken }
                    WallaBase.uploadNewArticle(
                        props,
                        articleUrl,
                        function( content, err ) {
                            onUploadArticleDone( content, err )
                            cb( err === null )
                        }
                    )
                }
            }
        )
    }

    function onUploadArticleDone( current, err ) {
        if ( err !== null ) {
            error( qsTr( "Failed to upload article: " ) + err )
        }
        else {
            var article = {
                id: current.id,
                created: current.created_at,
                updated: current.updated_at,
                mimetype: current.mimetype,
                language: current.language,
                readingTime: current.reading_time,
                url: current.url,
                domain: current.domain_name,
                archived: current.is_archived,
                starred: current.is_starred,
                title: current.title,
                previewPicture: current.previewPicture,
                content: current.content
            }
            WallaBase.saveArticle( article )
        }

        articlesDownloaded( [] )
    }

    function toggleArticleStar( article, cb ) {
        connect(
            function( err ) {
                if ( err !== null ) {
                    error( qsTr( "Failed to connect to server: " ) + err );
                    cb( false )
                }
                else {
                    var articleUrl = settings.base_url;
                    if ( articleUrl.charAt( articleUrl.length - 1 ) !== "/" )
                        articleUrl += "/"
                    articleUrl += "api/entries/" + article.id + ".json"

                    var json = {}
                    json.starred = ( article.starred ? 0 : 1 )

                    console.debug( "Setting starred to " + json.starred + " on article " + article.id )

                    httpRequester.patch(
                        articleUrl,
                        accessToken,
                        JSON.stringify( json ),
                        function( patchResponse, patchError ) {
                            onToggleArticleStarDone( patchResponse, patchError, article )
                            cb( patchError === null )
                        }
                    )
                }
            }
        )
    }

    function onToggleArticleStarDone( content, err, article ) {
        if ( err !== null ) {
            error( qsTr( "Failed to set star status on article: " ) + err )
        }
        else {
            console.debug( "Done toggling starred status for article " + article.id )
            var json = JSON.parse( content )
            WallaBase.setArticleStar( article.id, json.is_starred )
        }
    }

    function toggleArticleRead( article, cb ) {
        connect(
            function( err ) {
                if ( err !== null ) {
                    error( qsTr( "Failed to connect to server: " ) + err )
                    cb( false )
                }
                else {
                    var articleUrl = settings.base_url;
                    if ( articleUrl.charAt( articleUrl.length - 1 ) !== "/" )
                        articleUrl += "/"
                    articleUrl += "api/entries/" + article.id + ".json"

                    var json = {}
                    json.archive = ( article.archived ? 0 : 1 )

                    console.debug( "Setting archived to " + json.archived + " on article " + article.id )

                    httpRequester.patch(
                        articleUrl,
                        accessToken,
                        JSON.stringify( json ),
                        function( patchResponse, patchError ) {
                            onToggleArticleReadDone( patchResponse, patchError, article )
                            cb( patchError === null )
                        }
                    )
                }
            }
        )
    }

    function onToggleArticleReadDone( content, err, article, cb ) {
        if ( err !== null ) {
            error( qsTr( "Failed to set read status on article: " ) + err )
        }
        else {
            console.debug( "Done toggling archived status for article " + article.id )
            var json = JSON.parse( content )
            WallaBase.setArticleRead( article.id, json.is_archived )
        }
    }

    function deleteArticle( id, cb ) {
        connect(
            function( err ) {
                if ( err !== null ) {
                    error( qsTr( "Failed to connect to server: " ) + err )
                    cb( false )
                }
                else {
                    var articleUrl = settings.base_url;
                    if ( articleUrl.charAt( articleUrl.length - 1 ) !== "/" )
                        articleUrl += "/"
                    articleUrl += "api/entries/" + id + ".json"

                    console.debug( "Deleting article " + id )

                    httpRequester.del(
                        articleUrl,
                        accessToken,
                        function( delResponse, delError ) {
                            onDeleteArticleDone( delResponse, delError, id )
                            cb( err === null )
                        }

                    )
                }
            }
        )
    }

    function onDeleteArticleDone( content, err, id, cb ) {
        if ( err !== null ) {
            error( qsTr( "Failed to delete article: " ) + err )
        }
        else {
            console.debug( "Done deleting article " + id )
            WallaBase.deleteArticle( id )
        }
    }
}
