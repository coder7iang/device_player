/// 应用签名信息
class AppSignatureInfo {
  final String md5;
  final String sha1;
  final String sha256;
  final String subject;
  final String issuer;
  final String serialNumber;
  final String validFrom;
  final String validTo;
  final String algorithm;

  AppSignatureInfo({
    this.md5 = '',
    this.sha1 = '',
    this.sha256 = '',
    this.subject = '',
    this.issuer = '',
    this.serialNumber = '',
    this.validFrom = '',
    this.validTo = '',
    this.algorithm = '',
  });
}
