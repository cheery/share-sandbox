$(function(){
    var editor = ace.edit("editor");
    editor.setTheme("ace/theme/twilight");
    editor.getSession().setMode("ace/mode/coffee");

    sharejs.open('main.coffee', 'text', function(error, doc) {
        if (error) {
            editor.setValue("could not connect to collaborative session");
            throw error;
        } else {
            doc.attach_ace(editor);
        }
    });

    editor.commands.addCommand({
        name: 'run',
        bindKey: {win: 'Ctrl-Return', mac: 'Command-Return'},
        exec: function(editor) {
            $('iframe#run').attr('src', '/run.html');
        },
        readOnly: true
    });

    editor.commands.addCommand({
        name: 'stop',
        bindKey: {win: 'Ctrl-Shift-Return', mac: 'Command-Shift-Return'},
        exec: function(editor) {
            $('iframe#run').attr('src', '/idle.html');
        },
        readOnly: true
    });

    var vim = false;
    $('button#vim').click(function(){
        if (vim) {
            vim = false;
            editor.setKeyboardHandler(null);
        } else {
            vim = true;
            editor.setKeyboardHandler("ace/keyboard/vim");
        }
        editor.focus();
    });

    $('button#run').click(function(){
        $('iframe#run').attr('src', '/run.html');
    });

    $('button#stop').click(function(){
        $('iframe#run').attr('src', '/idle.html');
        editor.focus();
    });
});
