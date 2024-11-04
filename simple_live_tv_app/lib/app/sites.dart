import 'package:simple_live_core/simple_live_core.dart';
import 'package:simple_live_tv_app/app/app_focus_node.dart';

class Sites {
  static final Map<String, Site> allSites = {
    "AcFun": Site(
      id: "acfun",
      logo: "assets/images/acfun.png",
      name: "AcFun",
      liveSite: AcFunSite(),
      index: 0,
    ),
    "bilibili": Site(
      id: "bilibili",
      logo: "assets/images/bilibili_2.png",
      name: "哔哩哔哩",
      liveSite: BiliBiliSite(),
      index: 1,
    ),
    "douyu": Site(
      id: "douyu",
      logo: "assets/images/douyu.png",
      name: "斗鱼直播",
      liveSite: DouyuSite(),
      index: 2,
    ),
    "huya": Site(
      id: "huya",
      logo: "assets/images/huya.png",
      name: "虎牙直播",
      liveSite: HuyaSite(),
      index: 3,
    ),
    "douyin": Site(
      id: "douyin",
      logo: "assets/images/douyin.png",
      name: "抖音直播",
      liveSite: DouyinSite(),
      index: 4,
    ),
  };

  static List<Site> get supportSites {
    return allSites.values.toList();
  }
}

class Site {
  final String id;
  final String name;
  final String logo;
  final LiveSite liveSite;
  final int index;
  AppFocusNode appFocusNode = AppFocusNode();
  Site({
    required this.id,
    required this.liveSite,
    required this.logo,
    required this.name,
    required this.index,
  });
}
