{
  lib,
  buildPythonPackage,
  fetchPypi,
  pythonAtLeast,
  flake8,
  orderedmultidict,
  pytestCheckHook,
  six,
}:

buildPythonPackage rec {
  pname = "furl";
  version = "2.1.4";
  format = "setuptools";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-h3ZXUBJmySkmlzn7X1mAU0pBq9a7q8s2fBNtHTsqYBU=";
  };

  # With python 3.11.4, invalid IPv6 address does throw ValueError
  # https://github.com/gruns/furl/issues/164#issuecomment-1595637359
  postPatch = ''
    substituteInPlace tests/test_furl.py \
      --replace '[0:0:0:0:0:0:0:1:1:1:1:1:1:1:1:9999999999999]' '[2001:db8::9999]'
  '';

  propagatedBuildInputs = [
    orderedmultidict
    six
  ];

  nativeCheckInputs = [
    flake8
    pytestCheckHook
  ];

  disabledTests = [
    # AssertionError: assert '//////path' == '////path'
    # https://github.com/gruns/furl/issues/176
    "test_odd_urls"
  ];

  pythonImportsCheck = [ "furl" ];

  meta = with lib; {
    description = "Python library that makes parsing and manipulating URLs easy";
    homepage = "https://github.com/gruns/furl";
    license = licenses.unlicense;
    maintainers = with maintainers; [ vanzef ];
  };
}
