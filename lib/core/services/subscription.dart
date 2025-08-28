enum Plan { basic, pro }

class SubscriptionService {
  Plan currentPlan;
  SubscriptionService({this.currentPlan = Plan.basic});

  bool get hasJobsAccess => currentPlan == Plan.pro;
}

final subscriptionService = SubscriptionService();
