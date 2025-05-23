{
  lib,
  fetchFromGitHub,
  pythonOlder,
  buildPythonPackage,
  setuptools,

  # propagated
  django,
  hiredis,
  lz4,
  msgpack,
  redis,

  # testing
  pkgs,
  pytest-cov-stub,
  pytest-django,
  pytest-mock,
  pytestCheckHook,
}:

buildPythonPackage rec {
  pname = "django-redis";
  version = "5.4.0";
  pyproject = true;

  disabled = pythonOlder "3.6";

  src = fetchFromGitHub {
    owner = "jazzband";
    repo = "django-redis";
    tag = version;
    hash = "sha256-m7z3c7My24vrSSnyfDQ/LlWhy7pV4U0L8LATMvkfczc=";
  };

  build-system = [ setuptools ];

  propagatedBuildInputs = [
    django
    lz4
    msgpack
    redis
  ];

  optional-dependencies = {
    hiredis = [ redis ] ++ redis.optional-dependencies.hiredis;
  };

  pythonImportsCheck = [ "django_redis" ];

  preCheck = ''
    export DJANGO_SETTINGS_MODULE=tests.settings.sqlite

    ${pkgs.valkey}/bin/redis-server &
    REDIS_PID=$!
  '';

  postCheck = ''
    kill $REDIS_PID
  '';

  nativeCheckInputs = [
    pytest-cov-stub
    pytest-django
    pytest-mock
    pytestCheckHook
  ] ++ lib.flatten (lib.attrValues optional-dependencies);

  pytestFlagsArray = [
    "-W"
    "ignore::DeprecationWarning"
  ];

  disabledTests = [
    # ModuleNotFoundError: No module named 'test_cache_options'
    "test_custom_key_function"
    # ModuleNotFoundError: No module named 'test_client'
    "test_delete_pattern_calls_delete_for_given_keys"
    "test_delete_pattern_calls_get_client_given_no_client"
    "test_delete_pattern_calls_make_pattern"
    "test_delete_pattern_calls_pipeline_delete_and_execute"
    "test_delete_pattern_calls_scan_iter"
    "test_delete_pattern_calls_scan_iter_with_count_if_itersize_given"
  ];

  __darwinAllowLocalNetworking = true;

  meta = with lib; {
    description = "Full featured redis cache backend for Django";
    homepage = "https://github.com/jazzband/django-redis";
    changelog = "https://github.com/jazzband/django-redis/releases/tag/${version}";
    license = licenses.bsd3;
    maintainers = with maintainers; [ hexa ];
  };
}
