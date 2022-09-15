return [[html {
  font-size: 14px;
  -webkit-user-select: none;
  user-select: none;
}

body {
  margin: 0;
  overflow: hidden;
  font-family: Verdana;
  font-size: 1rem;
  line-height: 1.375rem;
  text-shadow: 1px 1px 1px #000, 1px 1px 2px #000;
  opacity: 0.9999;
}

/* hiding when panel is closed */

.panel-closed #text-entry, .panel-closed .dismiss-button {
  visibility: hidden;
}
.panel-closed #chatbox::-webkit-scrollbar-track, .panel-closed #chatbox::-webkit-scrollbar-thumb, .panel-closed #message-container > .message {
  background-color: transparent;
}

#chatbox {
  display: block;
  position: absolute;
  height: auto;
  bottom: 0;
  top: 0;
  left: 0;
  right: 0;
  margin-bottom: 30px;
  padding-right: 2px;
  overflow-x: hidden;
  overflow-y: scroll;
}
#chatbox::-webkit-scrollbar {
  width: 8px;
}
#chatbox::-webkit-scrollbar-track {
  background: rgba(0,0,0,0.5);
  border-radius: 4px;
}
#chatbox::-webkit-scrollbar-thumb {
  background: rgb(30,30,30);
  border-radius: 4px;
}
#load-button-wrapper {
  margin: 2px 0 4px 0;
  width: 100%;
  text-align: center;
}
#load-button {
  padding: 4px;
  color: #fff;
  font-size: 0.8rem;
  font-weight: bold;
  background-color: rgba(0,0,0,0.5);
  border-radius: 4px;
  margin: 0 auto;
  text-align: center;
  cursor: pointer;
}
#load-button.loading {
  font-style: italic;
  cursor: default;
  pointer-events: none;
}

#text-entry {
  position: fixed;
  padding: 4px;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0,0,0,0.5);
  border-radius: 4px;
}
#entry-button {
  float: right;
  margin-left: 2px;
  width: 1.375rem;
  height: 1.375rem;
  cursor: pointer;
}
#entry-input {
  resize: none;
  overflow: hidden;
  outline: none;
  color: #fff;
  white-space: nowrap;
  -webkit-user-select: text;
  user-select: text;
}
#entry-input[placeholder]:empty:before {
  content: attr(placeholder);
  cursor: text;
  position: absolute;
  opacity: 0.65;
}

.player {
  font-weight: bold;
  cursor: pointer;
}

div.message {
  padding: 0.25rem;
  min-height: 1.4rem;
  white-space: pre-wrap;
  word-wrap: break-word;
  overflow: hidden;
  pointer-events: all;
}
.message:first-child {
  border-top-left-radius: 4px;
  border-top-right-radius: 4px;
}
.message:last-child {
  border-bottom-left-radius: 4px;
  border-bottom-right-radius: 4px;
}
.message:nth-child(odd) {
  background-color: rgba(0,0,0,0.1);
}
.message:nth-child(even) {
  background-color: rgba(0,0,0,0.2);
}
.message:hover {
  background-color: rgba(0,0,0,0.3);
}

.message-content, .message-attachments {
  -webkit-user-select: text;
  user-select: text;
}

.message-content *, .message-attachments * {
  vertical-align: top;
}

/* message option styling */

.message.dismissible > .message-content {
  padding-right: 4rem;
}
.message.dismissible > .message-content > .dismiss-button {
  position: absolute;
  font-size: 0.8rem;
  color: #00aff4;
  cursor: pointer;
  right: 6px;
  -webkit-user-select: none;
  user-select: none;
  pointer-events: all;
}
.dismiss-button:before {
  content: "Dismiss";
}
.dismiss-button:hover {
  text-decoration: underline;
}

.message.center-content > .message-content {
  display: table;
  margin: 0 auto;
  text-align: center;
}
.message.center-attachments > .message-attachments {
  display: table;
  margin: 0 auto;
}
.message.unselect-content > .message-content *, .message.unselect-attachments > .message-attachments * {
  -webkit-user-select: none;
  user-select: none;
}
.message.untouch-content > .message-content *, .message.untouch-attachments > .message-attachments * {
  pointer-events: none;
}

.message.show-timestamp > .message-content > .timestamp {
  font-size: 0.8rem;
  color: #fff;
  background-color: rgba(0,0,0,0.5);
  border-radius: 4px;
  margin: -0.25rem 4px -0.25rem 0;
  padding: 0.25rem;
  -webkit-user-select: none;
  user-select: none;
  pointer-events: none;
}

/* markdown styling */

.spoiler {
  margin: -0.15rem;
  padding: 0.15rem;
  background: #000;
}
.spoiler span {
  opacity: 0;
}
.spoiler:hover span {
  opacity: 1;
}

span.link, span.safe-link {
  color: #00aff4;
  cursor: pointer;
  pointer-events: all;
}
span.link:hover, span.safe-link:hover {
  text-decoration: underline;
}

div.attachment {
  display: inline-block;
  margin-top: 4px;
  margin-right: 4px;
  border-radius: 4px;
  color: #fff;
  overflow: hidden;
  cursor: pointer;
}
.attachment > * {
  display: inline-block;
  max-width: 100%;
  border-radius: 4px;
  /* height is handled by cvar */
}
.attachment.loading, .attachment.failed, .attachment.blocked, .attachment.hidden {
  padding: 0.25rem;
  font-size: 0.8rem;
  background-color: rgba(0,0,0,0.5);
  -webkit-user-select: none;
  user-select: none;
}
.attachment.loading > *, .attachment.failed > *, .attachment.blocked > *, .attachment.hidden > * {
  display: none;
}
.attachment.loading::before {
  content: "Attachment (loading...)";
}
.attachment.failed::before {
  content: "Attachment (failed to load)";
}
.attachment.blocked::before {
  content: "Attachment (not whitelisted)";
}
.attachment.hidden::before {
  content: "Attachment (hidden)";
}

video, audio {
  outline: unset;
  font-weight: bold;
  text-shadow: none;
}

img.emoji {
  display: inline-block;
  width: 1.375rem;
  height: 1.375rem;
  cursor: pointer;
}
.emoji.jumbo {
  width: 3em;
  height: 3em;
}]]