<?php

require_once __DIR__. "/vendor/autoload.php";

use Symfony\Component\Process\Process;

while (true) {
	$cronjobActions = [
		"manage/browse/exceptions/update_exceptions",
		"admin/data_rules/track_exceptions",
		"cronjob/removeTempFiles"
	];
	foreach ($cronjobActions as $action) {
		$command = sprintf("php /srv/aims/index.php %s", $action);
		$process = new Process($command);
		$process->run();
		printf("%s success: %s\n", $command, $process->isSuccessful() ? "yes" : "no");
	}

	sleep(5);
}