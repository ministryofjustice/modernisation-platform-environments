import boto3
from models.upload_file_info import FileInfo


class PaymentS3Bucket:
    def __init__(self, bucket_name: str):
        self.s3 = boto3.client('s3')
        self.bucket = bucket_name
        self.new_file_prefix = ""
        self.processed_file_dir = "completed/"
        self.failed_file_dir = "failed/"

    def list_pending_excel_files(self) -> list[FileInfo]:
        file_list = self.list_files(prefix=self.new_file_prefix)
        excel_files_info = [self.get_file_info(filename=f.get("Key"), size=f.get("Size"))
                            for f in file_list
                            if f.get("Key", "").endswith(".xlsx")]
        return excel_files_info

    def list_processed_filenames(self) -> list[str]:
        return self.list_filenames(prefix=self.processed_file_dir)

    def list_filenames(self, prefix: str = "", delimiter: str = "/") -> list[str]:
        """
        Returns the filenames (Keys) from within specified directory (Prefix).
        Removes the path/directory name from result, so processed/myfile.xlsx,
        becomes just myfile.xlsx
        """
        file_details = self.list_files(prefix, delimiter)
        return [f.get("Key", "").split(delimiter)[-1] for f in file_details]

    def list_files(self, prefix: str = "", delimiter: str = "/") -> list[dict]:
        """Returns list of standard dicts supplied by s3.list_objects_v2
        The dictionary keys are: 'Key', 'LastModified', 'ETag','Size' and 'StorageClass'
        """
        # AWS advise using list_objects_v2 in preference to list_objects
        result = self.s3.list_objects_v2(Bucket=self.bucket, Prefix=prefix, Delimiter=delimiter)
        files_found = result.get("Contents")
        # If no files found "Contents" is None. Empty list would be more helpful here
        if files_found is None:
            files_found = []
        return files_found

    def move_file_to_processed(self, filename: str):
        self.move_file(filename, self.processed_file_dir + filename)

    def move_file_to_failed(self, filename: str):
        self.move_file(filename, self.failed_file_dir + filename)

    def move_file(self, source_file: str, destination: str):
        source = f"/{self.bucket}/{source_file}"
        response = self.s3.copy_object(
            CopySource=source,   # /Bucket-name/path/filename
            Bucket=self.bucket,  # Destination bucket
            Key=destination      # Destination path/filename
            )
        if response["ResponseMetadata"]["HTTPStatusCode"] == 200:
            # Note file specified in different way from s3.copy_object!
            self.s3.delete_object(Bucket=self.bucket, Key=source_file)

    def get_file_content(self, filename: str) -> bytes:
        file_object = self.s3.get_object(Bucket=self.bucket, Key=filename)
        file_content = file_object['Body'].read()
        return file_content

    def get_file_info(self, filename: str, size: int) -> FileInfo:
        file_object = self.s3.get_object(Bucket=self.bucket, Key=filename)
        file_info = FileInfo(filename=filename,
                             size=size,
                             content_type=file_object.get("ContentType"),
                             content_length=file_object.get("ContentLength")
                             )
        return file_info
