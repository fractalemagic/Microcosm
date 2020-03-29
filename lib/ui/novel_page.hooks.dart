part of "novel_page.dart";

Resource<Novel> _useNovel(String source, String slug) {
  final novelProvider = useNovelProvider();
  final dao = novelProvider.dao;
  final novel = useResource<Novel>();

  useEffect(() {
    dao.get(source: source, slug: slug).then((value) {
      novel.value = Resource.data(value);
    }).catchError((error) {
      novel.value = Resource.error(error);
    });

    return () {};
  }, []);

  return novel.value;
}

_PageState _usePageState() {
  return useContext().findAncestorWidgetOfExactType<_PageState>();
}

GestureTapCallback _useVisitChapter(Chapter chapter) {
  final router = useRouter();

  return () {
    router.push().reader(url: chapter.url);
  };
}
