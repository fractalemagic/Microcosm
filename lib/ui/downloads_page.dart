import "package:app/models/chapter.dart";
import "package:app/models/novel.dart";
import "package:app/ui/routes.dart" as routes;
import "package:app/widgets/downloaded_chapters.dart";
import 'package:app/widgets/image_view.dart';
import "package:app/widgets/novel_holder.dart";
import "package:app/widgets/novels_with_downloads.dart";
import "package:app/widgets/settings_icon_button.dart";
import "package:flutter/material.dart";
import "package:meta/meta.dart";

class DownloadsPage extends StatelessWidget {
  const DownloadsPage(this.novel);

  final String novel;

  @override
  Widget build(BuildContext context) {
    return novel != null ? new _ChaptersPage(slug: novel) : new _NovelsPage();
  }
}

class _NovelsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        automaticallyImplyLeading: false,
        leading: null,
        title: const Text("Downloads"),
        centerTitle: false,
        actions: const <Widget>[
          const SettingsIconButton(),
        ],
      ),
      body: new _NovelsPageBody(),
    );
  }
}

class _NovelsWithDownloads extends StatefulWidget {
  const _NovelsWithDownloads({@required this.builder});

  final AsyncWidgetBuilder<List<Novel>> builder;

  @override
  State createState() => new _NovelsWithDownloadsState();
}

class _NovelsWithDownloadsState extends State<_NovelsWithDownloads> {
  final _providerKey = new GlobalKey<NovelsWithDownloadsState>();

  var _deactivated = false;

  @override
  void deactivate() {
    super.deactivate();
    _deactivated = true;
  }

  @override
  Widget build(BuildContext context) {
    // Refresh downloads upon reactivation
    if (_deactivated) {
      _providerKey.currentState?.refresh();
      _deactivated = false;
    }

    return new NovelsWithDownloads(key: _providerKey, builder: widget.builder);
  }
}

class _NovelsPageBody extends StatelessWidget {
  IndexedWidgetBuilder _empty() {
    return (BuildContext context, int index) {
      return const Padding(
        padding: const EdgeInsets.only(
          top: 16.0,
        ),
        child: const Center(
          child: const Text("Nothing to see here"),
        ),
      );
    };
  }

  IndexedWidgetBuilder _builder(List<Novel> novels) {
    return (BuildContext context, int index) {
      return new _NovelItem(novels[index]);
    };
  }

  @override
  Widget build(BuildContext context) {
    return new _NovelsWithDownloads(
      builder: (BuildContext context, AsyncSnapshot<List<Novel>> snapshot) {
        final novels = snapshot.data;

        return new CustomScrollView(
          slivers: <Widget>[
            new SliverPadding(
              padding: const EdgeInsets.symmetric(
                vertical: 16.0,
              ),
              sliver: new SliverList(
                delegate: new SliverChildBuilderDelegate(
                  novels?.isNotEmpty != true ? _empty() : _builder(novels),
                  // Minimum one child for the empty view
                  childCount: novels?.isNotEmpty != true ? 1 : novels.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NovelItem extends StatelessWidget {
  const _NovelItem(this.novel);

  final Novel novel;

  @override
  Widget build(BuildContext context) {
    return new Container(
      // Increase the height of the tile to add padding
      constraints: new BoxConstraints(
        minHeight: 72.0,
      ),
      child: new ListTile(
        onTap: () {
          Navigator.of(context).push(routes.downloads(novelSlug: novel.slug));
        },
        leading: new ImageView(image: novel.posterImage),
        title: new Text(novel.name),
      ),
    );
  }
}

class _ChaptersPage extends StatelessWidget {
  const _ChaptersPage({@required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context) {
    return new NovelHolder(
      slug: slug,
      builder: (BuildContext context, AsyncSnapshot<Novel> snapshot) {
        final novel = snapshot.data;

        return new Scaffold(
          appBar: new AppBar(
            automaticallyImplyLeading: false,
            leading: null,
            title: new Text(novel?.name ?? "Loading"),
            centerTitle: false,
            actions: const <Widget>[
              const SettingsIconButton(),
            ],
          ),
          body: new _ChaptersPageBody(slug: slug),
        );
      },
    );
  }
}

class _DownloadedChapters extends StatefulWidget {
  const _DownloadedChapters({this.novelSlug, @required this.builder});

  final String novelSlug;

  final AsyncWidgetBuilder<List<Chapter>> builder;

  @override
  State createState() => new _DownloadedChaptersState();
}

class _DownloadedChaptersState extends State<_DownloadedChapters> {
  final _providerKey = new GlobalKey<DownloadedChaptersState>();

  var _deactivated = false;

  @override
  void deactivate() {
    super.deactivate();
    _deactivated = true;
  }

  @override
  Widget build(BuildContext context) {
    if (_deactivated) {
      _providerKey.currentState?.refresh();
      _deactivated = false;
    }

    return new DownloadedChapters(
      key: _providerKey,
      builder: widget.builder,
    );
  }
}

class _ChaptersPageBody extends StatelessWidget {
  const _ChaptersPageBody({@required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context) {
    return new DownloadedChapters(
      novelSlug: slug,
      builder: (BuildContext context, AsyncSnapshot<List<Chapter>> snapshot) {
        final chapters = snapshot.data;
        return new _ChapterList(chapters);
      },
    );
  }
}

class _ChapterList extends StatelessWidget {
  const _ChapterList(this.chapters);

  final List<Chapter> chapters;

  Widget _builder(BuildContext context, int index) {
    return new _ChapterItem(chapters[index]);
  }

  @override
  Widget build(BuildContext context) {
    if (chapters == null || chapters.isEmpty) {
      return const Padding(
        padding: const EdgeInsets.only(
          top: 16.0,
        ),
        child: const Center(
          child: const Text("Nothing to see here"),
        ),
      );
    }

    return new ListView.builder(
      padding: const EdgeInsets.symmetric(
        vertical: 8.0,
      ),
      itemBuilder: _builder,
      itemCount: chapters.length,
    );
  }
}

class _ChapterItem extends StatelessWidget {
  _ChapterItem(this.chapter);

  final Chapter chapter;

  @override
  Widget build(BuildContext context) {
    return new ListTile(
      onTap: () {
        Navigator.of(context).push(routes.reader(url: chapter.url));
      },
      title: new Text(chapter.title),
    );
  }
}
