declare namespace Redis {

	type MessageOf<K extends ValidChannel> = Subscriptions[K];
	type ValidChannel = keyof Subscriptions & string;
	type ValueOf<K extends string> = K extends keyof Schema ? Schema[K] : never;

	interface Schema {

		"dukpearl:discord:register": true;
        
		[key: `dukpearl:discord:interaction:${ string }`]: string | true;
        
		[key: `dukpearl:discord:ignlink:${ string }:message`]: { type: "interaction-original", applicationId: string, token: string };

		[key: `dukpearl:discord:ignlink:${ string }:user`]: { id: string };

		[key: `dukpearl:discord:ignlink:${ string }:lock`]: true;

		[key: `dukpearl:stasis:pearl:${ number }:owner`]: string;

		[key: `dukpearl:stasis:claim:${ string }`]: string;

		[key: `dukpearl:queue:${ string }:eta`]: { factor: number, pow: number };

		[key: `dukpearl:bot:online:${ string }`]: { host: string };

		[key: `dukpearl:mcacache:${ string }`]: z.infer<typeof zMojangUser>;

	}

	interface Subscriptions {

		[key: `dukpearl:cluster:${ string }`]: ClusterMessage;

		[key: `dukpearl:stasis:status:${ string }`]: "arrived" | "failed" | "queued" | "succeeded" | "timed-out";

	}

	type ClusterMessage =
		| {
			type: "bot-connect",
			bot: {
				id: string,
				name: string,
				version: string
			}
		}
		| {
			type: "request-load",
			playerUuid: string,
			destinationUuid: string,
			statusKey?: `dukpearl:stasis:status:${ string }`,
			notify?: boolean,
		}
		| {
			type: "stasis-query",
			id: string,
			from: string,
			playerUuid: string,
			locations: string[],
		}
		| {
			type: "stasis-reply",
			id: string,
			from: string,
			stasis: Array<{ id: string, distance: number | null }> | null,
		}

}