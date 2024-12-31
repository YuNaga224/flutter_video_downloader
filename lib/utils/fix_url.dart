// URLを修正するヘルパーメソッド
String fixUrl(String url) {
  url = url.trim();
  
  // httpsで始まらないURLを修正
  if (!url.startsWith('https://')) {
    if (url.startsWith('ttps://')) {
      url = 'h$url';
    } else if (url.startsWith('tps://')) {
      url = 'ht$url';
    } else if (url.startsWith('ps://')) {
      url = 'htt$url';
    } else if (url.startsWith('s://')) {
      url = 'http$url';
    } else if (url.startsWith('://')) {
      url = 'https$url';
    } else if (!url.startsWith('http://')) {
      // プロトコルが完全に欠けている場合
      url = 'https://$url';
    }
  }
  
  return url;
}