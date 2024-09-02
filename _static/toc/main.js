$(document).ready(function () {
    console.log("processing menu")
    var headers = $(".contents.topic > ul > li > ul")[0];
    $(".contents.topic > ul").hide();
    $(".contents.topic").append(headers);
});
