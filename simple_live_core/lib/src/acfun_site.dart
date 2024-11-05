import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:simple_live_core/src/common/http_client.dart';
import 'package:simple_live_core/src/danmaku/acfun_danmaku.dart';
import 'package:simple_live_core/src/interface/live_danmaku.dart';
import 'package:simple_live_core/src/interface/live_site.dart';
import 'package:simple_live_core/src/model/live_anchor_item.dart';
import 'package:simple_live_core/src/model/live_category.dart';
import 'package:simple_live_core/src/model/live_message.dart';
import 'package:simple_live_core/src/model/live_room_item.dart';
import 'package:simple_live_core/src/model/live_search_result.dart';
import 'package:simple_live_core/src/model/live_room_detail.dart';
import 'package:simple_live_core/src/model/live_play_quality.dart';
import 'package:simple_live_core/src/model/live_category_result.dart';
import 'package:html_unescape/html_unescape.dart';

class AcFunSite implements LiveSite {
  @override
  String id = "acfun";

  @override
  String name = "AcFun";

  @override
  LiveDanmaku getDanmaku() => AcFunDanmaku();

  @override
  Future<List<LiveCategory>> getCategores() async {
    List<LiveCategory> categories = [];
    var result =
        await HttpClient.instance.getJson("https://live.acfun.cn/api/channel/list");
    for (var item in result["channelFilters"]["liveChannelDisplayFilters"]["displayFilters"]) {
      var name = item["name"];
      var filterId = item["filterId"];
      List<LiveSubCategory> subCategories = [];
      categories.add(
        LiveCategory(
          id: filterId.toString(),
          name: name.toString(),
          children: subCategories,
        ),
      );
    }
    // 根据ID排序
    categories.sort((a, b) => int.parse(a.id).compareTo(int.parse(b.id)));

    return categories;
  }

  @override
  Future<LiveCategoryResult> getCategoryRooms(LiveSubCategory category,
      {int page = 1}) async {
    var result = await HttpClient.instance.getJson(
      "https://live.acfun.cn/api/channel/list?count=100&pcursor=&filters=[%7B%22filterType%22:1,+%22filterId%22:${category.id}%7D]",
      queryParameters: {},
    );

    var items = <LiveRoomItem>[];
    for (var item in result['liveList']) {
      var roomItem = LiveRoomItem(
        cover: item['coverUrls'][0].toString(),
        online: item['onlineCount'],
        roomId: item['authorId'].toString(),
        title: item['title'].toString(),
        userName: item['user']['name'].toString(),
      );
      items.add(roomItem);
    }
    var hasMore = page < (result['channelListData']['totalCount'] / result['channelListData']['count'] + 1);
    return LiveCategoryResult(hasMore: hasMore, items: items);
  }

  @override
  Future<List<LivePlayQuality>> getPlayQualites(
      {required LiveRoomDetail detail}) async {
    List<LivePlayQuality> qualities = [];
    var data = await getVideoPlayRes(detail.roomId);

    if (data.isEmpty) {
      return qualities;
    }

    var videoplayres = json.loads(data);
    var liveadaptivemanifest = videoplayres['liveAdaptiveManifest'];
    var adaptationset = liveadaptivemanifest['adaptationSet'];
    var representation = adaptationset['representation'];

    for (var item in representation) {
      qualities.add(LivePlayQuality(
        quality: item["name"],
        data: item["bitrate"],
      ));
    }
    return qualities;
  }

  @override
  Future<List<String>> getPlayUrls(
      {required LiveRoomDetail detail,
      required LivePlayQuality quality}) async {

    List<String> urls = [];
    var data = await getVideoPlayRes(detail.roomId);

    if (data.isEmpty) {
      return urls;
    }

    var videoplayres = json.loads(data);
    var liveadaptivemanifest = videoplayres['liveAdaptiveManifest'];
    var adaptationset = liveadaptivemanifest['adaptationSet'];
    var representation = adaptationset['representation'];
    for (var subItem in representation) {
      var url = subItem['url'];
      if (url.isNotEmpty && subItem['name'] == quality.quality) {
        urls.add(url);
      }
    }
    return urls;
  }

  Future<String> getVideoPlayRes(
      String roomId) async {
    var result1 = await HttpClient.instance.postJson(
      "https://id.app.acfun.cn/rest/app/visitor/login",
      data: 'sid=acfun.api.visitor',
      header: {
        'content-type': 'application/x-www-form-urlencoded',
        'cookie': '_did=H5_',
        'referer': 'https://m.acfun.cn/'
      },
      formUrlEncoded: true,
    );

    var userid = result1['userId'];
    var visitor_st = result1['acfun.api.visitor_st'];

    var result2 = await HttpClient.instance.postJson(
      "https://api.kuaishouzt.com/rest/zt/live/web/startPlay",
      data: 'authorId=$roomId&pullStreamType=FLV',
      params: {
          'subBiz': 'mainApp',
          'kpn': 'ACFUN_APP',
          'kpf': 'PC_WEB',
          'userId': ${userid},
          'did': 'H5_',
          'acfun.api.visitor_st': ${visitor_st}
      },
      header: {
        'content-type': 'application/x-www-form-urlencoded',
        'cookie': '_did=H5_',
        'referer': 'https://m.acfun.cn/'
      },
      formUrlEncoded: true,
    );

    if (result2['result'] == 1) {
      var data = result2['data'];
      return jsonEncode(data['videoPlayRes']);;
    } else {
      return "";
    }
  }

  @override
  Future<LiveCategoryResult> getRecommendRooms({int page = 1}) async {
  //   var result = await HttpClient.instance.getJson(
  //     "https://www.douyu.com/japi/weblist/apinc/allpage/6/$page",
  //     queryParameters: {},
  //   );

    var items = <LiveRoomItem>[];
  //   for (var item in result['data']['rl']) {
  //     if (item["type"] != 1) {
  //       continue;
  //     }
  //     var roomItem = LiveRoomItem(
  //       cover: item['rs16'].toString(),
  //       online: item['ol'],
  //       roomId: item['rid'].toString(),
  //       title: item['rn'].toString(),
  //       userName: item['nn'].toString(),
  //     );
  //     items.add(roomItem);
  //   }
  //   var hasMore = page < result['data']['pgcnt'];
    return LiveCategoryResult(hasMore: false, items: items);
  }

  @override
  Future<LiveRoomDetail> getRoomDetail({required String roomId}) async {
  //   Map roomInfo = await _getRoomInfo(roomId);

  //   var jsEncResult = await HttpClient.instance.getText(
  //       "https://www.douyu.com/swf_api/homeH5Enc?rids=$roomId",
  //       queryParameters: {},
  //       header: {
  //         'referer': 'https://www.douyu.com/$roomId',
  //         'user-agent':
  //             "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36 Edg/114.0.1823.43"
  //       });
  //   var crptext = json.decode(jsEncResult)["data"]["room$roomId"].toString();

    return LiveRoomDetail();
  //   return LiveRoomDetail(
  //     cover: roomInfo["room_pic"].toString(),
  //     online: int.tryParse(roomInfo["room_biz_all"]["hot"].toString()) ?? 0,
  //     roomId: roomInfo["room_id"].toString(),
  //     title: roomInfo["room_name"].toString(),
  //     userName: roomInfo["owner_name"].toString(),
  //     userAvatar: roomInfo["owner_avatar"].toString(),
  //     introduction: roomInfo["show_details"].toString(),
  //     notice: "",
  //     status: roomInfo["show_status"] == 1 && roomInfo["videoLoop"] != 1,
  //     danmakuData: roomInfo["room_id"].toString(),
  //     data: await getPlayArgs(crptext, roomInfo["room_id"].toString()),
  //     url: "https://www.douyu.com/$roomId",
  //     isRecord: roomInfo["videoLoop"] == 1,
  //   );
  }

  @override
  Future<LiveSearchRoomResult> searchRooms(String keyword,
      {int page = 1}) async {
  //   var did = generateRandomString(32);
  //   var result = await HttpClient.instance.getJson(
  //     "https://www.douyu.com/japi/search/api/searchShow",
  //     queryParameters: {
  //       "kw": keyword,
  //       "page": page,
  //       "pageSize": 20,
  //     },
  //     header: {
  //       'User-Agent':
  //           'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36 Edg/114.0.1823.51',
  //       'referer': 'https://www.douyu.com/search/',
  //       'Cookie': 'dy_did=$did;acf_did=$did'
  //     },
  //   );
  //   if (result['error'] != 0) {
  //     throw Exception(result['msg']);
  //   }
    var items = <LiveRoomItem>[];
  //   for (var item in result["data"]["relateShow"]) {
  //     var roomItem = LiveRoomItem(
  //       roomId: item["rid"].toString(),
  //       title: item["roomName"].toString(),
  //       cover: item["roomSrc"].toString(),
  //       userName: item["nickName"].toString(),
  //       online: parseHotNum(item["hot"].toString()),
  //     );
  //     items.add(roomItem);
  //   }
  //   var hasMore = result["data"]["relateShow"].isNotEmpty;
  //   return LiveSearchRoomResult(hasMore: hasMore, items: items);
    return LiveSearchRoomResult(hasMore: false, items: items);
  }

  // Future<Map> _getRoomInfo(String roomId) async {
  //   var result = await HttpClient.instance.getJson(
  //       "https://www.douyu.com/betard/$roomId",
  //       queryParameters: {},
  //       header: {
  //         'referer': 'https://www.douyu.com/$roomId',
  //         'user-agent':
  //             'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36 Edg/114.0.1823.43',
  //       });
  //   Map roomInfo;
  //   if (result is String) {
  //     roomInfo = json.decode(result)["room"];
  //   } else {
  //     roomInfo = result["room"];
  //   }
  //   return roomInfo;
  // }

  //生成指定长度的16进制随机字符串
  // String generateRandomString(int length) {
  //   var random = Random.secure();
  //   var values = List<int>.generate(length, (i) => random.nextInt(16));
  //   StringBuffer stringBuffer = StringBuffer();
  //   for (var item in values) {
  //     stringBuffer.write(item.toRadixString(16));
  //   }
  //   return stringBuffer.toString();
  // }

  @override
  Future<LiveSearchAnchorResult> searchAnchors(String keyword,
      {int page = 1}) async {
  //   var did = generateRandomString(32);
  //   var result = await HttpClient.instance.getJson(
  //     "https://www.douyu.com/japi/search/api/searchUser",
  //     queryParameters: {
  //       "kw": keyword,
  //       "page": page,
  //       "pageSize": 20,
  //       "filterType": 1,
  //     },
  //     header: {
  //       'User-Agent':
  //           'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36 Edg/114.0.1823.51',
  //       'referer': 'https://www.douyu.com/search/',
  //       'Cookie': 'dy_did=$did;acf_did=$did'
  //     },
  //   );

    var items = <LiveAnchorItem>[];
  //   for (var item in result["data"]["relateUser"]) {
  //     var liveStatus =
  //         (int.tryParse(item["anchorInfo"]["isLive"].toString()) ?? 0) == 1;
  //     var roomType =
  //         (int.tryParse(item["anchorInfo"]["roomType"].toString()) ?? 0);
  //     var roomItem = LiveAnchorItem(
  //       roomId: item["anchorInfo"]["rid"].toString(),
  //       avatar: item["anchorInfo"]["avatar"].toString(),
  //       userName: item["anchorInfo"]["nickName"].toString(),
  //       liveStatus: liveStatus && roomType == 0,
  //     );
  //     items.add(roomItem);
  //   }
  //   var hasMore = result["data"]["relateUser"].isNotEmpty;
  //   return LiveSearchAnchorResult(hasMore: hasMore, items: items);
    return LiveSearchAnchorResult(hasMore: false, items: items);
  }

  @override
  Future<bool> getLiveStatus({required String roomId}) async {
    var data = await getVideoPlayRes(roomId);
    return data.isNotEmpty;
  }

  // Future<String> getPlayArgs(String html, String rid) async {
  //   //取加密的js
  //   html = RegExp(
  //               r"(vdwdae325w_64we[\s\S]*function ub98484234[\s\S]*?)function",
  //               multiLine: true)
  //           .firstMatch(html)
  //           ?.group(1) ??
  //       "";
  //   html = html.replaceAll(RegExp(r"eval.*?;}"), "strc;}");

  //   var result = await HttpClient.instance.postJson(
  //       "http://alive.nsapps.cn/api/AllLive/DouyuSign",
  //       data: {"html": html, "rid": rid});

  //   if (result["code"] == 0) {
  //     return result["data"].toString();
  //   }
  //   return "";
  // }

  // int parseHotNum(String hn) {
  //   try {
  //     var num = double.parse(hn.replaceAll("万", ""));
  //     if (hn.contains("万")) {
  //       num *= 10000;
  //     }
  //     return num.round();
  //   } catch (_) {
  //     return -999;
  //   }
  // }

  @override
  Future<List<LiveSuperChatMessage>> getSuperChatMessage(
      {required String roomId}) {
    //尚不支持
    return Future.value([]);
  }
}

// class DouyuPlayData {
//   final int rate;
//   final List<String> cdns;
//   DouyuPlayData(this.rate, this.cdns);
// }
