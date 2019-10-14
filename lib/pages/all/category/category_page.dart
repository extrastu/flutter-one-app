///分类二级页面

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:flutter_one_app/entity/category/category_essay_entity.dart';
import 'package:flutter_one_app/entity/category/category_hp_entity.dart';
import 'package:flutter_one_app/entity/category/category_music_entity.dart';
import 'package:flutter_one_app/entity/category/category_question_entity.dart';
import 'package:flutter_one_app/entity/category/category_serial_content_entity.dart';
import 'package:flutter_one_app/pages/all/category/category_page_item.dart';
import 'package:flutter_one_app/utils/date_utils.dart';
import 'package:flutter_one_app/utils/refresh_utils.dart';
import '../../../api/api.dart';
import '../../../utils/net_utils.dart';

class categoryPage extends StatefulWidget {
  final arguments;

  categoryPage({this.arguments});

  @override
  _categoryPageState createState() {
    return _categoryPageState();
  }
}

class _categoryPageState extends State<categoryPage> {
  int _num;
  String _title;
  String _type;
  EasyRefreshController _controller = EasyRefreshController();
  List _data = List();
  String _nowMonth;

  @override
  void initState() {
    super.initState();
    _num = 1;
    _title = widget.arguments['name'];
    _type = widget.arguments['type'];
    _nowMonth = DateUtil.formatDate(DateTime.now(), format: DataFormats.y_mo);
    getData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void getData() {
    NetUtils.get(
      Api.getCategoryUrl(_type, _nowMonth),
      success: (response) {
        var entity;
        switch (_type) {
          case "hp":
            entity = CategoryHpEntity.fromJson(json.decode(response));
            break;
          case "question":
            entity = CategoryQuestionEntity.fromJson(json.decode(response));
            break;
          case "essay":
            entity = CategoryEssayEntity.fromJson(json.decode(response));
            break;
          case "serialcontent":
            entity =
                CategorySerialContentEntity.fromJson(json.decode(response));
            break;
          case "music":
            entity = CategoryMusicEntity.fromJson(json.decode(response));
            break;
          default:
            break;
        }
        if (entity != null && entity.data != null && _data != null) {
          if (entity.data.length > 0) {
            setState(() {
              _data.add(entity);
            });
          } else {
            ///如果上一个月无数据，尝试搜索往前10个月的数据
            if (_num % 10 != 0) {
              print("往上一个月加载重试次数:$_num");
              _nowMonth = DateUtil.getLastMonth(_nowMonth);
              getData();
            }
            _num++;
          }
        }
      },
      fail: (exception) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _title,
          style: TextStyle(
            color: Colors.black,
            letterSpacing: 3.0,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: Container(
        color: Colors.white,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: <Widget>[
            Visibility(
              child: Center(
                child: CircularProgressIndicator(
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(Colors.blue),
                ),
              ),
              visible: _data.length == 0,
              maintainState: false,
              maintainAnimation: false,
              maintainSize: false,
            ),
            EasyRefresh.custom(
              header: RefreshUtils.defaultHeader(),
              footer: RefreshUtils.defaultFooter(),
              controller: _controller,
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: Container(
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        return categoryPageItem(_type, _data[index].data);
                      },
                      separatorBuilder: (context, index) {
                        return Divider(
                          height: 0,
                          color: Colors.white,
                        );
                      },
                      itemCount: _data.length,
                    ),
                  ),
                ),
              ],
              onRefresh: () async {
                setState(() {
                  _data.clear();
                });
                _nowMonth = DateUtil.formatDate(DateTime.now(),
                    format: DataFormats.y_mo);
                getData();
                _controller.resetLoadState();
              },
              onLoad: () async {
                _nowMonth = DateUtil.getLastMonth(_nowMonth);
                getData();
                _controller.finishLoad();
              },
            ),
          ],
        ),
      ),
    );
  }
}