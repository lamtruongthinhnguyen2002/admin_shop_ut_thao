enum PageStatus { initial, loading, success, failure }

class PageState<T> {
  final PageStatus status;
  final T? data;
  final String? errorMessage;

  const PageState._({required this.status, this.data, this.errorMessage});

  const PageState.initial() : this._(status: PageStatus.initial);
  const PageState.loading() : this._(status: PageStatus.loading);
  PageState.success(T data) : this._(status: PageStatus.success, data: data);
  PageState.failure(String msg) : this._(status: PageStatus.failure, errorMessage: msg);

  bool get isInitial  => status == PageStatus.initial;
  bool get isLoading  => status == PageStatus.loading;
  bool get isSuccess  => status == PageStatus.success;
  bool get isFailure  => status == PageStatus.failure;
}