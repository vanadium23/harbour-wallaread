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
import Sailfish.WebView 1.0
import Sailfish.WebEngine 1.0
import Sailfish.Silica 1.0

import "../types"

WebViewPage {
    id: articlePage
    allowedOrientations: Orientation.All

    property int id
    property string title
    property string content
    property int archived
    property int starred

    property alias server: server

    Server {
        id: server

        onError: {
            showError( message )
        }
    }


    Row {
        id: actionsRow
        width: parent.width
        spacing: Theme.paddingLarge
        x: ( width / 2 ) - ( ( 2 * spacing + starButton.width + toggleReadButton.width + deleteButton.width ) / 2 )

        IconButton {
            id: starButton
            icon.source: articlePage.starred ? "image://theme/icon-m-favorite-selected" : "image://theme/icon-m-favorite"

            onClicked: {
                starButton.enabled = false

                articlePage.server.toggleArticleStar(
                    { id: id, starred: starred },
                    function( success ) {
                        articlePage.starred = articlePage.starred ? 0 : 1;
                        starButton.enabled = true;
                    }
                )
            }
        }

        IconButton {
            id: toggleReadButton
            icon.source: "image://theme/icon-m-acknowledge" + ( articlePage.archived ? "?" + Theme.secondaryColor : "" )

            onClicked: {
                toggleReadButton.enabled = false

                articlePage.server.toggleArticleRead(
                    { id: id, archived: archived },
                    function( success ) {
                        articlePage.archived = articlePage.archived ? 0 : 1;
                        toggleReadButton.enabled = true;
                    }
                )
            }
        }

        IconButton {
            id: deleteButton
            icon.source: "image://theme/icon-m-delete"

            onClicked: {
                articlePage.server.deleteArticle(
                    id,
                    function( success ) {
                        if ( !success ) {
                            showError( err )
                        } else {
                            var page = pageStack.push( Qt.resolvedUrl( "ArticlesPage.qml" ) )
                        }
                    }
                )
            }
        }
    }

    WebView {
        id: webview
        anchors {
            top: actionsRow.bottom
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }

        Component.onCompleted: {
            loadHtml( wrapArticleContent() )
        }
    }

    function wrapArticleContent() {
        var html =
            '<!DOCTYPE html>' +
            "<html>" +
            "<head>" +
                '<meta name="viewport" content="initial-scale=1.0">' +
                "<style type=\"text/css\">" +
                "article { font-family: sans-serif; font-size: 16px; }" +
                "article h1 { font-size: 32px; }" +
                "article img { max-width: 100%; height: auto; }" +
                "</style>" +
            "</head>" +
            "<body>" +
                "<article>" +
                "<h1>" + articlePage.title + "</h1>" +
                articlePage.content +
                "</article>" +
            "</body>" +
            "</html>"

        return html
    }
}
